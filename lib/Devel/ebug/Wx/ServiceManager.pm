package Devel::ebug::Wx::ServiceManager;

use strict;
use base qw(Class::Accessor::Fast);

use Module::Pluggable
      sub_name    => 'services',
      search_path => 'Devel::ebug::Wx::Service',
      require     => 1,
      except      => qr/::Base$/;

__PACKAGE__->mk_ro_accessors( qw(_active_services _wxebug) );

sub active_services { @{$_[0]->_active_services} }

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new;
    my @services = map $_->new, $self->services;

    $self->{_active_services} = \@services;

    return $self;
}

sub initialize {
    my( $self, $wxebug ) = @_;

    foreach my $service ( $self->active_services ) {
        next if $service->initialized;
        $service->initialize( $wxebug );
        $service->initialized( 1 );
    }
}

sub load_state {
    my( $self ) = @_;

    $_->load_state foreach $self->active_services;
}

sub finalize {
    my( $self, $wxebug ) = @_;

    # distinguish between explicit and implicit state saving?
    $_->save_state foreach $self->active_services;
}

sub get_service {
    my( $self, $wxebug, $name ) = @_;
    my( $service, @rest ) = grep $_->service_name eq $name,
                                 $self->active_services;

    # FIXME what if more than one?
    unless( $service->initialized ) {
        $service->initialize( $wxebug );
        $service->initialized( 1 );
    }
    return $service;
}

1;
