package Wx::Spice::Command::ShowView;

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
            my $parent = $viewmanager->main_window;

            # show if present, recreate if not present
            if( $viewmanager->has_view( $tag ) ) {
                if( $viewmanager->is_shown( $tag ) ) {
                    $viewmanager->hide_view( $tag );
                } else {
                    $viewmanager->show_view( $tag );
                }
            } else {
                my $instance = $view->new( $parent, $sm );
                $viewmanager->create_pane_and_update
                  ( $instance, { name    => $instance->tag, # for multiviews
                                 float   => 1,
                                 caption => $instance->description,
                                 } );
            }
        };
        push @commands, 'show_' . $tag . '_view',
             { sub         => $cmd,
               };
    }

    return @commands;
}

1;
