package Devel::ebug::Wx::Command::Views;

use strict;

sub register_commands {
    my( $class, $wxebug ) = @_;
    my @commands;

    foreach my $view ( $wxebug->view_manager_service->views ) {
        my $cmd = sub {
            my( $wx ) = @_;

            my $instance = $view->new( $wx, $wx );
            $wxebug->view_manager_service->create_pane_and_update
              ( $instance, { name    => $view->tag,
                             float   => 1,
                             caption => $view->description,
                             } );
        };
        push @commands, 'show_' . $view->tag,
             { sub      => $cmd,
               menu     => 'view',
               label    => sprintf( "Show %s", $view->description ),
               priority => 200,
               };
    }

    return @commands;
}

1;
