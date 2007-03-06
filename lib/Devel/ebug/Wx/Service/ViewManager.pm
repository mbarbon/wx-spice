package Devel::ebug::Wx::Service::ViewManager;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);

use Module::Pluggable
      sub_name    => 'views',
      search_path => 'Devel::ebug::Wx::View',
      require     => 1,
      except      => qr/::Base$|::View::Code::|::SUPER/;

__PACKAGE__->mk_accessors( qw(wxebug active_views manager pane_info) );

sub service_name { 'view_manager' }

sub initialize {
    my( $self, $wxebug ) = @_;

    $self->{wxebug} = $wxebug;
    $self->{manager} = Wx::AuiManager->new;
    $self->{active_views} = [];
    $self->views; # force loading of views

    $self->manager->SetManagedWindow( $wxebug );

    $self->{pane_info} = Wx::AuiPaneInfo->new
        ->CenterPane->TopDockable->BottomDockable->LeftDockable->RightDockable
        ->Floatable->Movable->PinButton->CaptionVisible->Resizable
        ->CloseButton->DestroyOnClose;
}

sub save_state {
    my( $self ) = @_;

    my $cfg = $self->wxebug->configuration_service->get_config( 'view_manager' );
    $cfg->Write( 'aui_perspective', $self->manager->SavePerspective );
    $cfg->Write( 'views', join ',', map ref( $_ ), @{$self->active_views} );
}

sub load_state {
    my( $self ) = @_;

    my $cfg = $self->wxebug->configuration_service->get_config( 'view_manager' );
    my $profile = $cfg->Read( 'aui_perspective', '' );
    my $views = $cfg->Read( 'views', '' );
    foreach my $class ( split /,/, $views ) {
        my $instance = $class->new( $self->wxebug, $self->wxebug );
        $self->manager->AddPane( $instance, Wx::AuiPaneInfo->new->Name( $instance->tag ) );
    }

    $self->manager->LoadPerspective( $profile ) if $profile;
    $self->manager->Update;
}

sub register_view {
    my( $self, $view ) = @_;

    push @{$self->active_views}, $view;
}

sub unregister_view {
    my( $self, $view ) = @_;

    $self->{active_views} = [ grep $_ ne $view, @{$self->active_views} ];
}

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

1;
