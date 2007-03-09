package Devel::ebug::Wx::Command::Views;

use strict;

sub register_commands {
    my( $class, $wxebug ) = @_;
    my @commands;

    my $viewmanager = $wxebug->view_manager_service;
    foreach my $view ( $viewmanager->views ) {
        my $cmd = sub {
            my( $wx ) = @_;

            return if $viewmanager->has_view( $view->tag );
            my $instance = $view->new( $wx, $wx );
            $viewmanager->create_pane_and_update
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
