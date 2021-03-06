use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [t1 => nobj => {}],
  )->then (sub {
    return $current->are_errors (
      [['follow', 'set.json'], {
        subject_nobj_key => $current->o ('a1')->{nobj_key},
        object_nobj_key => $current->o ('a2')->{nobj_key},
        verb_nobj_key => $current->o ('t1')->{nobj_key},
        value => 8,
      }],
      [
        ['new_nobj', 'subject'],
        ['new_nobj', 'object'],
        ['new_nobj', 'verb'],
      ],
    );
  })->then (sub {
    return $current->json (['follow', 'set.json'], { 
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
      verb_nobj_key => $current->o ('t1')->{nobj_key},
      value => 4,
    });
  })->then (sub {
    return $current->json (['follow', 'list.json'], {
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $v = $result->{json}->{items}->[0];
      is $v->{subject_nobj_key}, $current->o ('a1')->{nobj_key};
      is $v->{object_nobj_key}, $current->o ('a2')->{nobj_key};
      is $v->{verb_nobj_key}, $current->o ('t1')->{nobj_key};
      is $v->{value}, 4;
      ok $v->{created};
      is $v->{timestamp}, $v->{timestamp};
    } $current->c, name => 'new follow';
    return $current->json (['follow', 'set.json'], { 
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
      verb_nobj_key => $current->o ('t1')->{nobj_key},
      value => 1,
    });
  })->then (sub {
    return $current->json (['follow', 'list.json'], {
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $v = $result->{json}->{items}->[0];
      is $v->{subject_nobj_key}, $current->o ('a1')->{nobj_key};
      is $v->{object_nobj_key}, $current->o ('a2')->{nobj_key};
      is $v->{verb_nobj_key}, $current->o ('t1')->{nobj_key};
      is $v->{value}, 1;
      ok $v->{created};
      is $v->{timestamp}, $v->{timestamp};
    } $current->c, name => 'update follow';
    return $current->json (['follow', 'set.json'], { 
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
      verb_nobj_key => $current->o ('t1')->{nobj_key},
      value => 0,
    });
  })->then (sub {
    return $current->json (['follow', 'list.json'], {
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c, name => 'remove follow';
  });
} n => 14, name => 'set follow relationship';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [t1 => nobj => {}],
    ['a2-followed' => nobj => {}],
    ['a2-any' => nobj => {}],
    [c1 => nobj => {}],
    [sub1 => topic_subscription => {topic => 'a2-any', subscriber => 'a2'}],
  )->then (sub {
    return $current->json (['follow', 'set.json'], { 
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
      verb_nobj_key => $current->o ('t1')->{nobj_key},
      value => 4,
      notification_topic_nobj_key => $current->o ('a2-followed')->{nobj_key},
      notification_topic_fallback_nobj_key => [
        $current->o ('a2-any')->{nobj_key},
      ],
    });
  })->then (sub {
    return $current->json (['notification', 'nevent', 'list.json'], {
      subscriber_nobj_key => $current->o ('a2')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $v = $result->{json}->{items}->[0];
      is $v->{data}->{subject_nobj_key}, $current->o ('a1')->{nobj_key};
      is $v->{data}->{object_nobj_key}, $current->o ('a2')->{nobj_key};
      is $v->{data}->{verb_nobj_key}, $current->o ('t1')->{nobj_key};
      is $v->{data}->{value}, 4;
      ok $v->{data}->{timestamp};
    } $current->c;
    return $current->json (['follow', 'set.json'], { 
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
      verb_nobj_key => $current->o ('t1')->{nobj_key},
      value => 4,
      notification_topic_nobj_key => $current->o ('a2-followed')->{nobj_key},
      notification_topic_fallback_nobj_key => [
        $current->o ('a2-any')->{nobj_key},
      ],
    });
  })->then (sub {
    return $current->json (['notification', 'nevent', 'list.json'], {
      subscriber_nobj_key => $current->o ('a2')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
    } $current->c, name => 'unchanged';
    return $current->json (['follow', 'set.json'], { 
      subject_nobj_key => $current->o ('a1')->{nobj_key},
      object_nobj_key => $current->o ('a2')->{nobj_key},
      verb_nobj_key => $current->o ('t1')->{nobj_key},
      value => 0,
      notification_topic_nobj_key => $current->o ('a2-followed')->{nobj_key},
      notification_topic_fallback_nobj_key => [
        $current->o ('a2-any')->{nobj_key},
      ],
    });
  })->then (sub {
    return $current->json (['notification', 'nevent', 'list.json'], {
      subscriber_nobj_key => $current->o ('a2')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
    } $current->c, name => 'unchanged';
  });
} n => 8, name => 'notification';

RUN;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
