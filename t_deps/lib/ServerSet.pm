package ServerSet;
use strict;
use warnings;
use Path::Tiny;
use File::Temp qw(tempdir);
use AbortController;
use Promise;
use Promised::Flow;
use Promised::File;
use Promised::Command::Signals;
use JSON::PS;
use DockerStack;
use Web::URL;
use Web::Transport::BasicClient;

my $RootPath = path (__FILE__)->parent->parent->parent->absolute;

{
  use Socket;
  sub is_listenable_port ($) {
    my $port = $_[0] or return 0;
    socket(my $svr,PF_INET,SOCK_STREAM,getprotobyname('tcp'))||die"socket: $!";
    setsockopt($svr,SOL_SOCKET,SO_REUSEADDR,pack("l",1))||die "setsockopt: $!";
    bind($svr, sockaddr_in($port, INADDR_ANY)) || return 0;
    listen($svr, SOMAXCONN) || return 0;
    close($svr);
    return 1;
  } # is_listenable_port
  my $EphemeralStart = 1024; my $EphemeralEnd = 5000; my $not = {};
  sub find_listenable_port () {
    for (1..10000) {
      my$port=int rand($EphemeralEnd-$EphemeralStart);next if$not->{$port}++;
      if (is_listenable_port $port) { $not->{$port}++; return $port }
    }
    die "Listenable port not found";
  } # find_listenable_port
}

sub wait_for_http ($$) {
  my ($url, $signal) = @_;
  my $client = Web::Transport::BasicClient->new_from_url ($url, {
    last_resort_timeout => 1,
  });
  return promised_cleanup {
    return $client->close;
  } promised_wait_until {
    die Promise::AbortError->new if $signal->aborted; # XXX abortsignal
    return (promised_timeout {
      return $client->request (url => $url)->then (sub {
        return not $_[0]->is_network_error;
      });
    } 1)->catch (sub {
      $client->abort;
      $client = Web::Transport::BasicClient->new_from_url ($url);
      return 0;
    });
  } timeout => 60, interval => 0.3, signal => $signal;
} # wait_for_http

sub _path ($$) {
  return $_[0]->{data_root_path}->child ($_[1]);
} # _path

sub _write_file ($$$) {
  my $self = $_[0];
  my $path = $self->_path ($_[1]);
  my $file = Promised::File->new_from_path ($path);
  return $file->write_byte_string ($_[2]);
} # _write_file

sub _write_json ($$$) {
  my $self = $_[0];
  return $self->_write_file ($_[1], perl2json_bytes $_[2]);
} # _write_json

sub _register_server ($$) {
  my ($self, $name) = @_;
  $self->{servers}->{$name} ||= do {
    my $port = find_listenable_port;
    my $listen_url = Web::URL->parse_string ("http://0:$port");
    my $client_url = Web::URL->parse_string ("$name.server.test");
    #XXX $proxy_data->{register}->("$name.server.test" => $listen_url);
    {listen_url => $listen_url, client_url => $client_url};
  };
} # _register_server

sub _listen_url ($$) {
  my ($self, $name) = @_;
  $self->_register_server ($name);
  return $self->{servers}->{$name}->{listen_url};
} # _listen_url

sub _listen_hostport ($$) {
  my ($self, $name) = @_;
  $self->_register_server ($name);
  return $self->{servers}->{$name}->{listen_url}->hostport;
} # _listen_hostport

sub _docker ($%) {
  my ($self, %args) = @_;
  my $storage_data = {};
  my $stop = sub { };
  return Promise->all ([
    Promised::File->new_from_path ($self->_path ('minio_config'))->mkpath,
    Promised::File->new_from_path ($self->_path ('minio_data'))->mkpath,
  ])->then (sub {
    $storage_data->{aws4} = [undef, undef, undef, 's3'];

    my $stack = DockerStack->new ({
      services => {
        minio => {
          image => 'minio/minio',
          volumes => [
            $self->_path ('minio_config')->absolute . ':/config',
            $self->_path ('minio_data')->absolute . ':/data',
          ],
          user => "$<:$>",
          command => [
            'server',
            #'--address', "0.0.0.0:9000",
            '--config-dir', '/config',
            '/data'
          ],
          ports => [
            $self->_listen_hostport ('storage') . ":9000",
          ],
        },
      },
    });
    $stack->propagate_signal (1);
    $stack->signal_before_destruction ('TERM');
    $stack->stack_name ($args{stack_name} // __PACKAGE__);
    $stack->use_fallback (1);
    $stack->abort_signal ($args{signal});
    my $out = '';
    $stack->logs (sub {
      my $v = $_[0];
      return unless defined $v;
      $v =~ s/^/docker: start: /gm;
      $v .= "\x0A" unless $v =~ /\x0A\z/;
      $out .= $v;
    });
    $stop = sub { return $stack->stop };
    return $stack->start->catch (sub {
      warn $out;
      die $_[0];
    });
  })->then (sub {
    my $config_path = $self->_path ('minio_config')->child ('config.json');
    return promised_wait_until {
      return Promised::File->new_from_path ($config_path)->read_byte_string->then (sub {
        my $config = json_bytes2perl $_[0];
        $storage_data->{aws4}->[0] = $config->{credential}->{accessKey};
        $storage_data->{aws4}->[1] = $config->{credential}->{secretKey};
        $storage_data->{aws4}->[2] = $config->{region};
        return defined $storage_data->{aws4}->[0] &&
               defined $storage_data->{aws4}->[1] &&
               defined $storage_data->{aws4}->[2];
      })->catch (sub { return 0 });
    } timeout => 60*3;
  })->then (sub {
    return wait_for_http $self->_listen_url ('storage'), $args{signal};
  })->then (sub {
    return [$storage_data, $stop, undef];
  })->catch (sub {
    my $e = $_[0];
    return Promise->resolve->then ($stop)->then (sub { die $e });
  });
} # _docker

sub _app ($%) {
  my ($self, %args) = @_;

  # XXX docker mode
  my $sarze = Promised::Command->new
      ([$RootPath->child ('perl'),
        $RootPath->child ('bin/sarze.pl'),
        $self->_listen_url ('app')->port]);
  $sarze->propagate_signal (1);
  # XXX abortsignal

  my $data = {};

  return Promise->all ([
#XXX    Promised::File->new_from_path ($args{config_template_path})->read_byte_string,
  ])->then (sub {
    my $config = {};

=pod
              
    my $config = json_bytes2perl $_[0]->[4];

              if (defined $mysqld_info) {
                $config->{dsns} = $mysqld_info->{dsns};
                $config->{alt_dsns} = $mysqld_info->{alt_dsns};
              }
              if (defined $accounts_info) {
                $config->{accounts_url} = $accounts_info->{url}->stringify;
                $config->{accounts_key} = $accounts_info->{key};
                $config->{accounts_context} = $accounts_info->{context};
                $config->{accounts_servers} = $accounts_info->{servers};
              }

=cut

              # XXX envs_for_docker in docker mode
#              $sarze->envs->{no_proxy} = 'localhost'; # for accounts server
#              $sarze->envs->{$_} = $proxy_data->{envs_for_test}->{$_}
#                  for keys %{$proxy_data->{envs_for_test}};

    $sarze->envs->{APP_CONFIG} = $self->_path ('app-config.json');
    return $self->_write_json ('app-config.json', $config);
  })->then (sub {
    return $sarze->run;
  })->then (sub {
    my $ac = AbortController->new;
    $sarze->wait->then (sub { $ac->abort });
    return wait_for_http
        (Web::URL->parse_string ('/robots.txt', $self->_listen_url ('app')),
         $ac->signal);
  })->then (sub {
    return [$data, sub { $sarze->send_signal ('TERM') }, $sarze->wait];
  });
} # _app

sub run ($%) {
  my ($class, %args) = @_;

  ## Arguments:
  ##   app_port       The port of the main application server.  Optional.
  ##   data_root_path Path::Tiny of the root of the server's data files.  A
  ##                  temporary directory (removed after shutdown) if omitted.
  ##   signal         AbortSignal canceling the server set.  Optional.

  ## Return a promise resolved into a hash reference of:
  ##   data
  ##     app_listen_url Web::URL of the main application server.
  ##   stop           CODE to stop the servers.
  ##   done           Promise fulfilled after the servers' shutdown.
  ## or rejected.

  my $self = bless {data_root_path => $args{data_root_path}}, $class;
  unless (defined $args{data_root_path}) {
    my $tempdir = tempdir (CLEANUP => 1);
    $self->{data_root_path} = path ($tempdir);
    $self->{_tempdir} = $tempdir;
  }

  my $servers = {
    _docker => {
      #stack_name
    },
    _app => {
      app_port => $args{app_port},
    },
  }; # $servers

  my $acs = {};
  for (keys %$servers) {
    $acs->{$_} = AbortController->new;
    $servers->{$_}->{signal} = $acs->{$_}->signal;
  }

  my @started;
  my @stopper;
  my @done;
  my @signal;
  my $stopped;
  my $stop = sub {
    my $cancel = $_[0] || sub { };
    $cancel->();
    $stopped = 1;
    @signal = ();
    $_->abort for values %$acs;
    my @s = @stopper;
    @stopper = ();
    return Promise->all ([map {
      Promise->resolve->then ($_)->catch (sub { });
    } @s]);
  }; # $stop
  
  $args{signal}->manakai_onabort (sub { $stop->() }) if defined $args{signal};
  push @signal, Promised::Command::Signals->add_handler (INT => $stop);
  push @signal, Promised::Command::Signals->add_handler (TERM => $stop);
  push @signal, Promised::Command::Signals->add_handler (KILL => $stop);

  my $error;
  for my $method (keys %$servers) {
    my $started = $self->$method (%{$servers->{$method}})->then (sub {
      my ($data, $stop, $done) = @{$_[0]};
      my ($r_s, $s_s) = promised_cv;
      push @stopper, sub { $s_s->(Promise->resolve->then ($stop)) };
      push @done, $done, $r_s;
      return undef;
    })->catch (sub {
      $error //= $_[0];
      $stop->();
    });
    push @started, $started;
    push @done, $started;
  } # $method

  return Promise->all (\@started)->then (sub {
    die $error // "Stopped" if $stopped;

    my $data = {};
    $data->{app_listen_url} = $self->_listen_url ('app');

    return {data => $data, stop => $stop, done => Promise->all (\@done)};
  })->catch (sub {
    my $e = $_[0];
    $stop->();
    return Promise->all (\@done)->then (sub { die $e });
  });
} # run

1;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
