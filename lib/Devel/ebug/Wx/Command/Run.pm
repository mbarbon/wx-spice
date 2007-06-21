package Devel::ebug::Wx::Command::Run;

use strict;
use Wx::Spice::Plugin qw(:plugin);

sub commands : Command {
    return
      ( run_menu => { tag      => 'run',
                      label    => 'Run',
                      priority => 200,
                      },
        next     => { sub      => sub { $_[0]->ebug_publisher_service->next },
                      key      => 'Alt-N',
                      menu     => 'run',
                      label    => 'Next',
                      priority => 20,
                      },
        step     => { sub      => sub { $_[0]->ebug_publisher_service->step },
                      key      => 'Alt-S',
                      menu     => 'run',
                      label    => 'Step',
                      priority => 20,
                      },
        return   => { sub      => sub { $_[0]->ebug_publisher_service->return },
                      key      => 'Alt-U',
                      menu     => 'run',
                      label    => 'Return',
                      priority => 20,
                      },
        run      => { sub      => sub { $_[0]->ebug_publisher_service->run },
                      key      => 'Alt-R',
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
    my( $sm ) = @_;

    $sm->ebug_publisher_service->reload_program;
}

1;
