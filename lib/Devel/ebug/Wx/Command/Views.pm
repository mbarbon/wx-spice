package Devel::ebug::Wx::Command::Views;

use strict;
use Wx::Spice::Plugin qw(:plugin);

sub commands : Command {
    my( $class, $sm ) = @_;
    my @commands;

    my $viewmanager = $sm->view_manager_service;
    foreach my $view ( $viewmanager->views ) {
        my $tag = $view->tag;
        my $cmd = sub {
            my( $sm ) = @_;
            my $wx = $sm->ebug_wx_service;

            # show if present, recreate if not present
            if( $viewmanager->has_view( $tag ) ) {
                if( $viewmanager->is_shown( $tag ) ) {
                    $viewmanager->hide_view( $tag );
                } else {
                    $viewmanager->show_view( $tag );
                }
            } else {
                my $instance = $view->new( $wx, $wx );
                $viewmanager->create_pane_and_update
                  ( $instance, { name    => $instance->tag, # for multiviews
                                 float   => 1,
                                 caption => $instance->description,
                                 } );
            }
        };
        my $update_ui = sub {
            my( $sm, $event ) = @_;

            $event->Check( $viewmanager->is_shown( $tag ) );
        };
        push @commands, 'show_' . $tag,
             { sub         => $cmd,
               menu        => 'view',
               update_menu => $update_ui,
               checkable   => 1,
               label       => sprintf( "Show %s", $view->description ),
               priority    => 200,
               };
    }

    return @commands;
}

1;
