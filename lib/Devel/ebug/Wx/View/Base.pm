package Devel::ebug::Wx::View::Base;

use strict;
use base qw(Wx::Spice::View::Base);

__PACKAGE__->mk_accessors( qw(wxebug) );

sub view_manager_service { $_[0]->wxebug->view_manager_service }

sub subscribe_ebug {
    my( $self, $event, $handler ) = @_;

    $self->_setup_destroy;
    $self->add_subscription( $self->ebug, $event, $handler );
}

sub ebug { $_[0]->wxebug->ebug }

1;
