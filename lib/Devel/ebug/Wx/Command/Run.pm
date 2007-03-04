package Devel::ebug::Wx::Command::Run;

use strict;

sub register_commands {
    return
      ( run_menu => { tag      => 'run',
                      label    => 'Run',
                      priority => 200,
                      },
        next     => { sub      => \&next,
                      key      => 'n',
                      menu     => 'run',
                      label    => 'Next',
                      priority => 20,
                      },
        step     => { sub      => \&step,
                      key      => 's',
                      menu     => 'run',
                      label    => 'Step',
                      priority => 20,
                      },
        return   => { sub      => \&return,
                      key      => 'u',
                      menu     => 'run',
                      label    => 'Return',
                      priority => 20,
                      },
        run      => { sub      => \&run,
                      key      => 'r',
                      menu     => 'run',
                      label    => 'Run',
                      priority => 10,
                      },
        );
}

sub next {
    my( $wx ) = @_;

    $wx->ebug->next;
}

sub step {
    my( $wx ) = @_;

    $wx->ebug->step;
}

sub run {
    my( $wx ) = @_;

    $wx->ebug->run;
}

sub return {
    my( $wx ) = @_;

    $wx->ebug->return;
}

1;
