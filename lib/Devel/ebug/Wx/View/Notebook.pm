package Devel::ebug::Wx::View::Notebook;

use Wx::AUI;

use strict;
use base qw(Wx::AuiNotebook Devel::ebug::Wx::View::Multi);

__PACKAGE__->mk_accessors( qw(has_views) );

use Wx qw(:aui);
use Wx::Event qw(EVT_RIGHT_UP EVT_MENU);

sub tag_base         { 'notebook' }
sub description_base { 'Notebook' }

sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1, -1], [-1, -1],
                                   wxAUI_NB_TAB_MOVE|wxAUI_NB_CLOSE_BUTTON|
                                   wxAUI_NB_WINDOWLIST_BUTTON );

    $self->wxebug( $wxebug );
    $self->register_view;
    $self->SetSize( $self->default_size );

    $self->AddPage( Wx::StaticText->new( $self, -1,
                                         "Use 'View -> Edit Notebooks'" ),
                    'Add pages' );

    return $self;
}

sub add_view {
    my( $self, $view ) = @_;
    my $instance = $self->wxebug->view_manager_service->get_view( $view->tag );

    if( !$self->has_views ) {
        $self->DeletePage( 0 );
    }
    # always destroy if present
    if( $instance ) {
        $instance->Destroy;
    }
    $instance = $view->new( $self, $self->wxebug );
    $self->AddPage( $instance, $instance->description );
    $self->has_views( 1 );
}

sub save_state {
    my( $self ) = @_;
    my $ps = $self->SUPER::save_state;

    return $ps unless $self->has_views;
    return $ps . '|' . join ';', map $_->serialize,
                                 map $self->GetPage( $_ ),
                                     ( 0 .. $self->GetPageCount - 1 );
}

sub load_state {
    my( $self, $state ) = @_;
    $state =~ /^(.*)\|(.*)$/ or die $state;
    $self->SUPER::load_state( $1 );

    $self->DeletePage( 0 ); # FIXME use non ad-hoc handling...

    # FIXME duplicated vith viewmanager
    foreach my $class ( split /;/, $2 ) {
        $class =~ /^([\w:]+)\((.*)\)$/ or next;
        my $instance = $1->new( $self, $self->wxebug );
        $instance->load_state( $2 );
        $self->AddPage( $instance, $instance->description );
        $self->has_views( 1 );
    }
}


1;
