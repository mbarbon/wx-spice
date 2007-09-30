package Devel::ebug::Wx::Service::ViewManager;

use strict;
use base qw(Wx::Spice::Service::Base);
use Wx::Spice::Plugin qw(:manager :plugin);

=head1 NAME

Devel::ebug::Wx::Service::ViewManager - manage view docking/undocking

=head1 SYNOPSIS

  Devel::ebug::Wx::Service::ViewManager->set_main_window_service( 'my_app' );

  my $vm = ...->get_service( 'view_manager' );
  my $bool = $vm->has_view( $tag );
  $vm->register_view( $view );
  $vm->unregister_view( $view );

  # both create_* methods don't call ->register_view()
  $vm->create_pane( $view, { name    => $tag,
                             caption => 'Displayed name',
                             float   => 1,
                             } );
  $vm->create_pane_and_update( ... ); # like ->create_pane()

  my @view_classes = Devel::ebug::Wx::Service::ViewManager->views;

=head1 DESCRIPTION

The C<view_manager> service manages windows (views) using the
wxWidgets Advanced User Interface (AUI).  The service automatically
manages saving/restoring the state and layout of registered views.
Unregistered views are allowed but their state is not preserved
between sessions.

=head1 METHODS

=cut

use Wx;
use Wx::AUI;
use Wx::Spice::ServiceManager::Holder;
use Wx::Spice::Service::SizeKeeper;

__PACKAGE__->mk_accessors( qw(main_window active_views manager pane_info) );

# this creates a dependency, but having a 'main_window' service would
# be a bit over-engineered
{
    my $main_window = 'main_window';
    sub set_main_window_service { $main_window = $_[1] }
    sub get_main_window_service { $main_window }
}

sub views { Wx::Spice::Plugin->view_classes }

sub service_name : Service { 'view_manager' }

sub initialize {
    my( $self, $manager ) = @_;

    $self->main_window( $manager->get_service( get_main_window_service() ) );
    $self->manager( Wx::AuiManager->new );
    $self->active_views( {} );
    $self->views; # force loading of views

    $self->manager->SetManagedWindow( $self->main_window );

    # default Pane Info
    $self->{pane_info} = Wx::AuiPaneInfo->new
        ->CenterPane->TopDockable->BottomDockable->LeftDockable->RightDockable
        ->Floatable->Movable->PinButton->CaptionVisible->Resizable
        ->CloseButton->DestroyOnClose( 0 );
}

sub save_configuration {
    my( $self ) = @_;

    my $cfg = $self->configuration_service->get_config( 'view_manager' );
    $cfg->set_value( 'aui_perspective', $self->manager->SavePerspective );
    $cfg->set_serialized_value( 'views', [ map  $_->get_layout_state,
                                           grep $_->is_managed,
                                                $self->active_views_list ] );
}

sub load_configuration {
    my( $self ) = @_;

    # FIXME alignment between the AUI config and views, grep out views
    #       without perspective
    my $cfg = $self->configuration_service->get_config( 'view_manager' );
    my $profile = $cfg->get_value( 'aui_perspective', '' );
    my $views = $cfg->get_serialized_value( 'views', [] );
    foreach my $view ( @$views ) {
        my $instance = $view->{class}->new( $self->main_window,
                                            $self->service_manager, $view );
        my $pane_info = $self->pane_info->Name( $instance->tag )
            ->DestroyOnClose( 0 );
        $pane_info->DestroyOnClose( 1 ) unless Wx->VERSION > 0.67;
        $pane_info->DestroyOnClose( 1 ) if    $instance->can( 'is_multiview' )
                                           && $instance->is_multiview;
        $self->manager->AddPane( $instance, $pane_info );
    }

    $self->manager->LoadPerspective( $profile ) if $profile;

    # destroy hidden multiviews (they can't currently be reshown)
    $_->Destroy foreach grep $_->can( 'is_multiview' ) && $_->is_multiview,
                        grep !$self->is_shown( $_->tag ),
                             $self->active_views_list;

    $self->window_size_keeper_service->register_window( 'viewmanager',
                                                        $self->main_window );

    $self->manager->Update;
}

# FIXME document get_state/set_state as part of view interface
sub save_program_state {
    my( $self, $file ) = @_;
    my $cfg = $self->get_service( 'configuration' )
                   ->get_config( 'view_manager', $file );

    foreach my $view ( $self->active_views_list ) {
        next unless $view->can( 'get_state' );
        $cfg->set_serialized_value( $view->tag, $view->get_state );
    }
}

sub load_program_state {
    my( $self, $file ) = @_;
    my $cfg = $self->get_service( 'configuration' )
                   ->get_config( 'view_manager', $file );

    # FIXME what about the state of an inactive view?
    foreach my $view ( $self->active_views_list ) {
        next unless $view->can( 'set_state' );
        my $state = $cfg->get_serialized_value( $view->tag );
        next unless $state;
        $view->set_state( $state );
    }
}

=head2 active_views_list

  my @views = $vm->active_views_list;

=cut

sub active_views_list {
    my( $self ) = @_;

    return values %{$self->active_views};
}

=head2 has_view

=head2 get_view

  my $is_active = $vm->has_view( $tag );
  my $view = $vm->get_view( $tag );

C<has_view> returns C<true> if a view vith the given tag is currently
shown and managed by the view manager; in this case C<get_view> can be
used to retrieve the view.

=cut

sub has_view {
    my( $self, $tag ) = @_;

    return exists $self->active_views->{$tag} ? 1 : 0;
}

sub get_view {
    my( $self, $tag ) = @_;

    return $self->active_views->{$tag};
}

=head2 register_view

  $vm->register_view( $view );

Registers a view with the view manager.  Please notice that at any
given time only one view can be registered with the service with a
given tag.

=cut

sub register_view {
    my( $self, $view ) = @_;

    $self->active_views->{$view->tag} = $view;
}

=head2 unregister_view

  $vm->unregister_view( $view );

Unregisters the view from the view manager.

=cut

sub unregister_view {
    my( $self, $view ) = @_;

    delete $self->active_views->{$view->tag};
    $self->manager->DetachPane( $view ) unless $self->finalized;
}

=head2 create_pane

=head2 create_pane_and_update

  $vm->create_pane( $view, { name    => 'view_tag',
                             caption => 'Pane title',
                             float   => 1,
                             } );
  $vm->create_pane_and_update( ... );

Both functions create a floatable pane containing C<$window>;
C<create_pane_and_update> also causes the pane to be shown.  Neither
function calls C<register_view> to register the view with the view
manager.

=cut

sub create_pane_and_update {
    my( $self, @args ) = @_;

    $self->create_pane( @args );
    $self->manager->Update;
}

sub create_pane {
    my( $self, $window, $info ) = @_;

    my $pane_info = $self->pane_info ->Name( $info->{name} )
        ->Caption( $info->{caption} )->DestroyOnClose( 0 );
    $pane_info->Float if $info->{float};
    $self->{pane_info}->DestroyOnClose( 1 ) unless Wx->VERSION > 0.67;
    $pane_info->DestroyOnClose( 1 ) if    $window->can( 'is_multiview' )
                                       && $window->is_multiview;
    $self->manager->AddPane( $window, $pane_info );
}

=head2 show_view

=head2 hide_view

  $vm->show_view( $tag );
  $vm->hide_view( $tag );
  my $shown = $vm->is_shown( $tag );

=cut

sub show_view {
    my( $self, $tag ) = @_;

    $self->manager->GetPane( $tag )->Show;
    $self->manager->Update;
}

sub hide_view {
    my( $self, $tag ) = @_;

    if( Wx->VERSION > 0.67 ) {
        $self->manager->GetPane( $tag )->Hide;
    } else {
        $self->manager->GetPane( $tag )->Destroy;
    }
    $self->manager->Update;
}

# FIXME needs to be smarter for Notebooks
sub is_shown {
    my( $self, $tag ) = @_;
    my $view = $self->get_view( $tag );

    return 1 if $view && !$view->is_managed;
    return 0 unless $self->has_view( $tag );
    return $self->manager->GetPane( $tag )->IsShown ? 1 : 0;
}

=head2 views

    my @view_classes = Devel::ebug::Wx::Service::ViewManager->views;

Returns a list of view classes known to the view manager.

=cut

1;
