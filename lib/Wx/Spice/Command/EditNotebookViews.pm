package Wx::Spice::Command::EditNotebookViews;

use strict;
use Wx::Spice::Plugin qw(:plugin);

sub command : Command {
    my( $class, $sm ) = @_;

    return ( 'edit_notebook_views' => { sub => \&_edit_notebook }
             );
}

sub _notebooks {
    my( $vm ) = @_;

    my @nbs = sort { $a->description cmp $b->description }
              grep $_->isa( 'Wx::Spice::View::Notebook' ),
                   $vm->active_views_list;
    return @nbs;
}

sub _valid_views {
    my( $vm ) = @_;

    my @views;
    foreach my $view ( $vm->views ) {
        next if $vm->is_shown( $view->tag );
        next if $view->isa( 'Wx::Spice::View::Notebook' );
        push @views, $view;
    }

    return @views;
}

sub _edit_notebook {
    my( $sm ) = @_;
    my $vm = $sm->view_manager_service;
    my $wx = $vm->main_window;
    my @nbs = _notebooks( $vm );
    my $nb_index = Wx::GetSingleChoiceIndex
      ( 'Choose the notebook you want to add views to',
        'Choose a notebook', [ map $_->description, @nbs ], $wx );
    return if $nb_index < 0;
    my @views = _valid_views( $vm );
    my @chs = Wx::GetMultipleChoices
      ( 'Choose the views to be added to ' . $nbs[$nb_index]->description ,
        'Choose views',
        [ map $_->description, @views ], $wx );
    return unless @chs;

    $nbs[$nb_index]->add_view( $views[$_] ) foreach @chs;
}

sub can_enable_command {
    my( $sm, $event ) = @_;

    my $vm = $sm->view_manager_service;
    return _notebooks( $vm ) && _valid_views( $vm ) ? 1 : 0;
}

1;
