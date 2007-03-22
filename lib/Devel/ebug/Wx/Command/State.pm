package Devel::ebug::Wx::Command::State;

use strict;

sub register_commands {
    return
      ( save_state => { sub      => \&save_program_state,
                        menu     => 'file',
                        label    => 'Save state',
                        priority => 100,
                        },
        load_state => { sub      => \&load_program_state,
                        menu     => 'file',
                        label    => 'Load state',
                        priority => 100,
                        },
        );
}

my $FILE = 'foo.ebug_wx';

sub load_program_state {
    my( $wx ) = @_;

    $wx->service_manager->maybe_call_method( 'load_program_state', $FILE );
}

sub save_program_state {
    my( $wx ) = @_;

    $wx->service_manager->maybe_call_method( 'save_program_state', $FILE );
    $wx->configuration_service->flush( $FILE );
}

1;
