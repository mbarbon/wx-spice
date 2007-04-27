package Devel::ebug::Wx::Plugin::Listener::Base;

use strict;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(_subscribed) );

sub add_subscription {
    my( $self, $source, @args ) = @_;

    $self->_subscribed( [] ) unless $self->_subscribed;
    $source->add_subscriber( @args );
    push @{$self->_subscribed}, [ $source, @args ];
}

sub delete_subscriptions {
    my( $self ) = @_;

    foreach my $sub ( @{$self->_subscribed || []} ) {
        $sub->[0]->delete_subscriber( @$sub[1 .. $#$sub] );
    }
    $self->_subscribed( undef );
}

1;
