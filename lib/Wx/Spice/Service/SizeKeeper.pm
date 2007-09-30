package Wx::Spice::Service::SizeKeeper;

use strict;
use base qw(Wx::Spice::Service::Base);
use Wx::Spice::Plugin qw(:manager :plugin);
use Wx::Spice::ServiceManager::Holder;

__PACKAGE__->mk_ro_accessors( qw(registered_windows) );

sub service_name : Service { 'window_size_keeper' }

sub new {
    return shift->SUPER::new( { registered_windows => {} } );
}

sub register_window {
    my( $self, $name, $window ) = @_;

    my $cfg = $self->configuration_service->get_config( 'window_size_keeper' );
    my( @xywh ) = split ',', $cfg->get_value( "${name}_geometry", ',,,' );
    if( @xywh && $xywh[0] && length $xywh[0] ) {
        $window->SetSize( @xywh );
    }

    $self->registered_windows->{$name} = $window;
}

sub save_configuration {
    my( $self ) = @_;

    my $cfg = $self->configuration_service->get_config( 'window_size_keeper' );
    while( my( $name, $window ) = each %{$self->registered_windows} ) {
        my( @xywh ) = ( $window->GetPositionXY, $window->GetSizeWH );
        $cfg->set_value( "${name}_geometry", sprintf '%d,%d,%d,%d', @xywh );
    }
}

1;
