package Devel::ebug::Wx::Command::Views;

use strict;
use Wx::Spice::Plugin qw(:plugin);

use Wx::Spice::Command::EditNotebookViews;
use Wx::Spice::Command::ShowView;

sub commands : MenuCommand {
    my( $class, $sm ) = @_;
    my @commands;

    my $viewmanager = $sm->view_manager_service;
    foreach my $view ( $viewmanager->views ) {
        my $tag = $view->tag;
        my $update_ui = sub {
            my( $sm, $event ) = @_;

            $event->Check( $viewmanager->is_shown( $tag ) );
        };
        push @commands, 'show_' . $tag . '_view',
             { id          => 'show_' . $tag . '_view',
               menu        => 'view',
               update_menu => $update_ui,
               checkable   => 1,
               label       => sprintf( "Show %s", $view->description ),
               priority    => 200,
               };
    }
    push @commands, 'edit_notebook_views',
         { id          => 'edit_notebook_views',
           menu        => 'view',
           update_menu => \&Wx::Spice::Command::EditNotebookViews::can_enable_command,
           label       => 'Edit notebooks',
           priority    => 300,
           };

    return @commands;
}

1;
