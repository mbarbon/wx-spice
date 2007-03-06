package Devel::ebug::Wx::Command::Run;

use strict;

sub register_commands {
    return
      ( run_menu => { tag      => 'run',
                      label    => 'Run',
                      priority => 200,
                      },
        next     => { sub      => sub { $_[0]->ebug->next },
                      key      => 'n',
                      menu     => 'run',
                      label    => 'Next',
                      priority => 20,
                      },
        step     => { sub      => sub { $_[0]->ebug->step },
                      key      => 's',
                      menu     => 'run',
                      label    => 'Step',
                      priority => 20,
                      },
        return   => { sub      => sub { $_[0]->ebug->return },
                      key      => 'u',
                      menu     => 'run',
                      label    => 'Return',
                      priority => 20,
                      },
        run      => { sub      => sub { $_[0]->ebug->run },
                      key      => 'r',
                      menu     => 'run',
                      label    => 'Run',
                      priority => 10,
                      },
        restart  => { sub      => \&restart,
                      menu     => 'run',
                      label    => 'Restart',
                      priority => 30,
                      },
        );
}

sub restart {
    my( $wx ) = @_;

    # FIXME save and restore program state
    $wx->ebug->load_program;
}

1;
