use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->are_errors (
      [['tag', 'edit.json'], {
        context_nobj_key => $current->o ('t1')->{nobj_key},
        tag_name => $current->generate_text (x2 => {}),
        operator_nobj_key => $current->o ('u1')->{nobj_key},
      }],
      [
        ['new_nobj', 'context'],
        ['new_nobj', 'operator'],
        ['json_opt', 'string_data'],
        ['json_opt', 'redirect'],
      ],
    );
  })->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->generate_text (x1 => {}),
      operator_nobj_key => $current->o ('u1')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->generate_text (x1 => {}),
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{count}, 0;
      is $tag->{timestamp}, 0;
      is $tag->{author_status}, 0;
      is $tag->{owner_status}, 0;
      is $tag->{admin_status}, 0;
    } $current->c;
  });
} n => 6, name => 'nop';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->generate_text (x1 => {}),
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      author_status => 4,
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      $current->set_o (tag1 => $tag);
      is $tag->{count}, 0;
      ok $tag->{timestamp};
      is $tag->{author_status}, 4;
      is $tag->{owner_status}, 0;
      is $tag->{admin_status}, 0;
    } $current->c;
    return $current->json (['nobj', 'statusinfo.json'], {
      target_nobj_key => $current->o ('tag1')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $s = $result->{json}->{info}->{$current->o ('tag1')->{nobj_key}};
      is $s->{author_data}->{ab}, undef;
      is $s->{owner_data}->{ab}, undef;
      is $s->{admin_data}->{ab}, undef;
      ok $s->{data}->{log_id};
      ok $s->{data}->{timestamp};
      is $s->{data}->{old}->{author_status}, 0;
      is $s->{data}->{old}->{owner_status}, 0;
      is $s->{data}->{old}->{admin_status}, 0;
      is $s->{data}->{new}->{author_status}, 4;
      is $s->{data}->{new}->{owner_status}, 0;
      is $s->{data}->{new}->{admin_status}, 0;
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      owner_status => 2,
      admin_status => 10,
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{count}, 0;
      ok $tag->{timestamp};
      is $tag->{author_status}, 4;
      is $tag->{owner_status}, 2;
      is $tag->{admin_status}, 10;
    } $current->c;
    return $current->json (['nobj', 'statusinfo.json'], {
      target_nobj_key => $current->o ('tag1')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $s = $result->{json}->{info}->{$current->o ('tag1')->{nobj_key}};
      is $s->{author_data}->{ab}, undef;
      is $s->{owner_data}->{ab}, undef;
      is $s->{admin_data}->{ab}, undef;
      ok $s->{data}->{log_id};
      ok $s->{data}->{timestamp};
      is $s->{data}->{old}->{author_status}, 4;
      is $s->{data}->{old}->{owner_status}, 0;
      is $s->{data}->{old}->{admin_status}, 0;
      is $s->{data}->{new}->{author_status}, 4;
      is $s->{data}->{new}->{owner_status}, 2;
      is $s->{data}->{new}->{admin_status}, 10;
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      status_info_author_data => '{"ab":53}',
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{count}, 0;
      ok $tag->{timestamp};
      is $tag->{author_status}, 4;
      is $tag->{owner_status}, 2;
      is $tag->{admin_status}, 10;
    } $current->c;
    return $current->json (['nobj', 'statusinfo.json'], {
      target_nobj_key => $current->o ('tag1')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $s = $result->{json}->{info}->{$current->o ('tag1')->{nobj_key}};
      is $s->{author_data}->{ab}, 53;
      is $s->{owner_data}->{ab}, undef;
      is $s->{admin_data}->{ab}, undef;
      ok $s->{data}->{log_id};
      ok $s->{data}->{timestamp};
      is $s->{data}->{old}->{author_status}, 4;
      is $s->{data}->{old}->{owner_status}, 2;
      is $s->{data}->{old}->{admin_status}, 10;
      is $s->{data}->{new}->{author_status}, 4;
      is $s->{data}->{new}->{owner_status}, 2;
      is $s->{data}->{new}->{admin_status}, 10;
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      status_info_author_data => '{}',
      status_info_owner_data => '{"ab":13}',
      status_info_admin_data => '{"ab":0.44}',
      admin_status => 30,
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{count}, 0;
      ok $tag->{timestamp};
      is $tag->{author_status}, 4;
      is $tag->{owner_status}, 2;
      is $tag->{admin_status}, 30;
    } $current->c;
    return $current->json (['nobj', 'statusinfo.json'], {
      target_nobj_key => $current->o ('tag1')->{nobj_key},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $s = $result->{json}->{info}->{$current->o ('tag1')->{nobj_key}};
      is $s->{author_data}->{ab}, undef;
      is $s->{owner_data}->{ab}, 13;
      is $s->{admin_data}->{ab}, 0.44;
      ok $s->{data}->{log_id};
      ok $s->{data}->{timestamp};
      is $s->{data}->{old}->{author_status}, 4;
      is $s->{data}->{old}->{owner_status}, 2;
      is $s->{data}->{old}->{admin_status}, 10;
      is $s->{data}->{new}->{author_status}, 4;
      is $s->{data}->{new}->{owner_status}, 2;
      is $s->{data}->{new}->{admin_status}, 30;
    } $current->c;
  });
} n => 64, name => 'status changed';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text (x1 => {}),
      string_data => {
        abc => 3534,
        xya => undef,
        "\x{901}" => '',
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
      sd => ['abc', 'xya', "\x{901}", 'bar'],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{string_data}->{abc}, 3534;
      is $tag->{string_data}->{xya}, undef;
      is $tag->{string_data}->{"\x{901}"}, '';
      is $tag->{string_data}->{bar}, undef;
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->o ('x1'),
      string_data => {
        "\x{901}" => "\x{5000}",
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
      sd => ['abc', 'xya', "\x{901}", 'bar'],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{string_data}->{abc}, 3534;
      is $tag->{string_data}->{xya}, undef;
      is $tag->{string_data}->{"\x{901}"}, "\x{5000}";
      is $tag->{string_data}->{bar}, undef;
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->o ('x1'),
      string_data => {
        "\x{901}" => undef,
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
      sd => ['abc', 'xya', "\x{901}", 'bar'],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag = $result->{json}->{tags}->{$current->o ('x1')};
      is $tag->{string_data}->{abc}, 3534;
      is $tag->{string_data}->{xya}, undef;
      is $tag->{string_data}->{"\x{901}"}, undef;
      is $tag->{string_data}->{bar}, undef;
    } $current->c;
  });
} n => 12, name => 'string_data';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text (x1 => {}),
      redirect => {
        to => $current->generate_text (x2 => {}),
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => $current->o ('x1'),
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{$current->o ('x1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('x2')};
      is $tag1->{tag_name}, $current->o ('x1');
      is $tag1->{canon_tag_name}, $current->o ('x2');
      is $tag2->{tag_name}, $current->o ('x2');
      is $tag2->{canon_tag_name}, $current->o ('x2');
    } $current->c, name => 'x1->x2';
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->o ('x2'),
      redirect => {
        to => $current->generate_text (x3 => {}),
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [$current->o ('x1'), $current->o ('x2')],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{$current->o ('x1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('x2')};
      my $tag3 = $result->{json}->{tags}->{$current->o ('x3')};
      is $tag1->{tag_name}, $current->o ('x1');
      is $tag1->{canon_tag_name}, $current->o ('x3');
      is $tag2->{tag_name}, $current->o ('x2');
      is $tag2->{canon_tag_name}, $current->o ('x3');
      is $tag3->{tag_name}, $current->o ('x3');
      is $tag3->{canon_tag_name}, $current->o ('x3');
    } $current->c, name => 'x1->x2 + x2->x3';
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text ('x0' => {}),
      redirect => {
        to => $current->o ('x2'),
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [$current->o ('x1'), $current->o ('x2'), $current->o ('x0')],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag0 = $result->{json}->{tags}->{$current->o ('x0')};
      my $tag1 = $result->{json}->{tags}->{$current->o ('x1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('x2')};
      my $tag3 = $result->{json}->{tags}->{$current->o ('x3')};
      is $tag0->{tag_name}, $current->o ('x0');
      is $tag0->{canon_tag_name}, $current->o ('x3');
      is $tag1->{tag_name}, $current->o ('x1');
      is $tag1->{canon_tag_name}, $current->o ('x3');
      is $tag2->{tag_name}, $current->o ('x2');
      is $tag2->{canon_tag_name}, $current->o ('x3');
      is $tag3->{tag_name}, $current->o ('x3');
      is $tag3->{canon_tag_name}, $current->o ('x3');
    } $current->c, name => 'x2->x3 + x0->x2';
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->o ('x2'),
      redirect => {
        to => undef,
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [$current->o ('x1'), $current->o ('x2'), $current->o ('x0')],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag0 = $result->{json}->{tags}->{$current->o ('x0')};
      my $tag1 = $result->{json}->{tags}->{$current->o ('x1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('x2')};
      my $tag3 = $result->{json}->{tags}->{$current->o ('x3')};
      is $tag0->{tag_name}, $current->o ('x0');
      is $tag0->{canon_tag_name}, $current->o ('x3');
      is $tag1->{tag_name}, $current->o ('x1');
      is $tag1->{canon_tag_name}, $current->o ('x3');
      is $tag2->{tag_name}, $current->o ('x2');
      is $tag2->{canon_tag_name}, $current->o ('x2');
      is $tag3->{tag_name}, $current->o ('x3');
      is $tag3->{canon_tag_name}, $current->o ('x3');
    } $current->c, name => 'x2->undef';
  });
} n => 26, name => 'redirect to';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text (x1 => {}),
      redirect => {
        to => $current->generate_text (x2 => {}),
      },
    });
  })->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->o ('x2'),
      redirect => {
        to => $current->o ('x1'),
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [$current->o ('x1'), $current->o ('x2')],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{$current->o ('x1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('x2')};
      is $tag1->{tag_name}, $current->o ('x1');
      is $tag1->{canon_tag_name}, $current->o ('x2');
      is $tag2->{tag_name}, $current->o ('x2');
      is $tag2->{canon_tag_name}, $current->o ('x2');
    } $current->c;
  });
} n => 4, name => 'redirect loop';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => "\x0A\x{FF20}  ",
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => "\x0A\x{FF20}  ",
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{"\x0A\x{FF20}  "};
      my $tag2 = $result->{json}->{tags}->{"\x40"};
      is $tag1->{tag_name}, "\x0A\x{FF20}  ";
      is $tag1->{canon_tag_name}, "\x40";
      is $tag2->{tag_name}, "\x40";
      is $tag2->{canon_tag_name}, "\x40";
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => "\x0A\x{FF20}  ",
      redirect => {to => "\x{FF21}\x0D"},
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => ["\x0A\x{FF20}  ", "\x{FF21}\x0D", "\x40"],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{"\x0A\x{FF20}  "};
      my $tag2 = $result->{json}->{tags}->{"\x40"};
      my $tag3 = $result->{json}->{tags}->{"\x{FF21}\x0D"};
      my $tag4 = $result->{json}->{tags}->{"\x41"};
      is $tag1->{tag_name}, "\x0A\x{FF20}  ";
      is $tag1->{canon_tag_name}, "\x41";
      is $tag2->{tag_name}, "\x40";
      is $tag2->{canon_tag_name}, "\x41";
      is $tag3->{tag_name}, "\x{FF21}\x0D";
      is $tag3->{canon_tag_name}, "\x41";
      is $tag4->{tag_name}, "\x41";
      is $tag4->{canon_tag_name}, "\x41";
    } $current->c;
  });
} n => 12, name => 'implicit redirect';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text (tag1 => {}),
      redirect => {
        langs => {
          foo => $current->generate_text (tag2 => {}),
          bar => $current->generate_text (tag3 => {}),
        },
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [
        $current->o ('tag2'),
        $current->o ('tag3'),
      ],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{$current->o ('tag1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('tag2')};
      my $tag3 = $result->{json}->{tags}->{$current->o ('tag3')};
      is $tag1->{tag_name}, $current->o ('tag1');
      is $tag1->{canon_tag_name}, $current->o ('tag1');
      is $tag2->{tag_name}, $current->o ('tag2');
      is $tag2->{canon_tag_name}, $current->o ('tag1');
      is $tag3->{tag_name}, $current->o ('tag3');
      is $tag3->{canon_tag_name}, $current->o ('tag1');
    } $current->c;
  });
} n => 6, name => 'lang redirects';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text (tag1 => {}),
      redirect => {
        to => $current->generate_text (tag4 => {}),
        langs => {
          foo => $current->generate_text (tag2 => {}),
          bar => $current->generate_text (tag3 => {}),
          abc => "\x{FF40}",
        },
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [
        $current->o ('tag2'),
        $current->o ('tag3'),
        $current->o ('tag1'),
        "\x{FF40}", "\x60",
      ],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{$current->o ('tag1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('tag2')};
      my $tag3 = $result->{json}->{tags}->{$current->o ('tag3')};
      my $tag4 = $result->{json}->{tags}->{$current->o ('tag4')};
      my $tag5 = $result->{json}->{tags}->{"\x{FF40}"};
      my $tag6 = $result->{json}->{tags}->{"\x60"};
      is $tag1->{tag_name}, $current->o ('tag1');
      is $tag1->{canon_tag_name}, $current->o ('tag4');
      is $tag2->{tag_name}, $current->o ('tag2');
      is $tag2->{canon_tag_name}, $current->o ('tag4');
      is $tag3->{tag_name}, $current->o ('tag3');
      is $tag3->{canon_tag_name}, $current->o ('tag4');
      is $tag4->{tag_name}, $current->o ('tag4');
      is $tag4->{canon_tag_name}, $current->o ('tag4');
      is $tag5->{tag_name}, "\x{FF40}";
      is $tag5->{canon_tag_name}, $current->o ('tag4');
      is $tag6->{tag_name}, "\x60";
      is $tag6->{canon_tag_name}, $current->o ('tag4');
    } $current->c;
  });
} n => 12, name => 'lang redirects to';

Test {
  my $current = shift;
  return $current->create (
    [t1 => nobj => {}],
    [u1 => nobj => {}],
    [_tag0 => tag => {context => 't1', operator => 'u1',
                      tag_name => $current->generate_text (tag0 => {}),
                      redirect => {
                        to => $current->generate_text (tag2 => {}),
                      }}],
  )->then (sub {
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->generate_text (tag1 => {}),
      redirect => {
        langs => {
          foo => $current->o ('tag2'),
          bar => $current->generate_text (tag3 => {}),
        },
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [
        $current->o ('tag0'),
        $current->o ('tag2'),
        $current->o ('tag3'),
      ],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag0 = $result->{json}->{tags}->{$current->o ('tag0')};
      my $tag1 = $result->{json}->{tags}->{$current->o ('tag1')};
      my $tag2 = $result->{json}->{tags}->{$current->o ('tag2')};
      my $tag3 = $result->{json}->{tags}->{$current->o ('tag3')};
      is $tag0->{tag_name}, $current->o ('tag0');
      is $tag0->{canon_tag_name}, $current->o ('tag1');
      is $tag1->{tag_name}, $current->o ('tag1');
      is $tag1->{canon_tag_name}, $current->o ('tag1');
      is $tag2->{tag_name}, $current->o ('tag2');
      is $tag2->{canon_tag_name}, $current->o ('tag1');
      is $tag3->{tag_name}, $current->o ('tag3');
      is $tag3->{canon_tag_name}, $current->o ('tag1');
    } $current->c;
    return $current->json (['tag', 'edit.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      operator_nobj_key => $current->o ('u1')->{nobj_key},
      tag_name => $current->o ('tag1'),
      redirect => {
        langs => {
          bar => undef,
        },
      },
    });
  })->then (sub {
    my $result = $_[0];
    return $current->json (['tag', 'list.json'], {
      context_nobj_key => $current->o ('t1')->{nobj_key},
      tag_name => [
        $current->o ('tag1'),
      ],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $tag1 = $result->{json}->{tags}->{$current->o ('tag1')};
      is $tag1->{tag_name}, $current->o ('tag1');
      is $tag1->{canon_tag_name}, $current->o ('tag1');
      is 0+keys %{$tag1->{localized_tag_names}}, 1;
      is $tag1->{localized_tag_names}->{foo}, $current->o ('tag2');
    } $current->c;
  });
} n => 12, name => 'lang redirect delete';

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
