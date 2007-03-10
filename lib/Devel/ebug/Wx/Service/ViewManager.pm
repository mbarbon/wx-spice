package Devel::ebug::Wx::Service::ViewManager;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);

use Wx::AUI;

=head1 NAME

Devel::ebug::Wx - GUI interface for your (d)ebugging needs

=head1 SYNOPSIS

  my $vm = ...->get_service( 'view_manager' );
  my $bool = $vm->has_view( $tag );
  $vm->register_view( $view );
  $vm->unregister_view( $view );

  # both don't call ->register_view()
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

use Module::Pluggable
      sub_name    => 'views',
      search_path => 'Devel::ebug::Wx::View',
      require     => 1,
      except      => qr/::Base$|::View::Code::|::SUPER/;

__PACKAGE__->mk_accessors( qw(wxebug active_views manager pane_info) );

sub service_name { 'view_manager' }

sub initialize {
    my( $self, $wxebug ) = @_;

    $self->wxebug( $wxebug );
    $self->manager( Wx::AuiManager->new );
    $self->active_views( {} );
    $self->views; # force loading of views

    $self->manager->SetManagedWindow( $wxebug );

    # default Pane Info
    $self->{pane_info} = Wx::AuiPaneInfo->new
        ->CenterPane->TopDockable->BottomDockable->LeftDockable->RightDockable
        ->Floatable->Movable->PinButton->CaptionVisible->Resizable
        ->CloseButton;
    $self->{pane_info}->DestroyOnClose unless Wx->VERSION > 0.67;
}

sub save_state {
    my( $self ) = @_;

    my $cfg = $self->wxebug->configuration_service->get_config( 'view_manager' );
    my( @xywh ) = ( $self->wxebug->GetPositionXY, $self->wxebug->GetSizeWH );
    $cfg->Write( 'aui_perspective', $self->manager->SavePerspective );
    $cfg->Write( 'views', join ',', map ref( $_ ),
                                        values %{$self->active_views} );
    $cfg->Write( 'frame_geometry', sprintf '%d,%d,%d,%d', @xywh );
}

sub load_state {
    my( $self ) = @_;

    my $cfg = $self->wxebug->configuration_service->get_config( 'view_manager' );
    my $profile = $cfg->Read( 'aui_perspective', '' );
    my $views = $cfg->Read( 'views', '' );
    foreach my $class ( split /,/, $views ) {
        my $instance = $class->new( $self->wxebug, $self->wxebug );
        my $pane_info = $self->pane_info->Name( $instance->tag );
        $pane_info->DestroyOnClose unless Wx->VERSION > 0.67;
        $self->manager->AddPane( $instance, $pane_info );
    }

    $self->manager->LoadPerspective( $profile ) if $profile;

    my( @xywh ) = split ',', $cfg->Read( 'frame_geometry', ',,,' );
    if( length $xywh[0] ) {
        $self->wxebug->SetSize( @xywh );
    }

    $self->manager->Update;
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

    my $pane_info = $self->pane_info
                         ->Name( $info->{name} )
                         ->Caption( $info->{caption} );
    $pane_info->Float if $info->{float};
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

sub is_shown {
    my( $self, $tag ) = @_;

    return $self->manager->GetPane( $tag )->IsShown;
}

=head2 views

    my @view_classes = Devel::ebug::Wx::Service::ViewManager->views;

Returns a list of view classes known to the view manager.

=cut

1;
