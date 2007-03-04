package Devel::ebug::Wx::View::Base;

use strict;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(wxebug _has_destroy _subscribed) );

# not yet in wxPerl
sub EVT_DESTROY($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_DESTROY, $_[2] ) }

sub subscribe_ebug {
    my( $self, $event, $handler ) = @_;

    $self->ebug->add_subscriber( $event, $handler );

    unless( $self->_has_destroy ) {
        $self->_subscribed( [] );
        $self->_has_destroy( 1 );
        EVT_DESTROY( $self, $self, \&_on_destroy );
    }
    push @{$self->_subscribed}, [ $event, $handler ];
}

sub _on_destroy {
    my( $self ) = @_;
    $self->ebug->delete_subscriber( @$_ ) foreach @{$self->_subscribed};
    $self->_subscribed( undef );
}

sub ebug { $_[0]->wxebug->ebug }

1;