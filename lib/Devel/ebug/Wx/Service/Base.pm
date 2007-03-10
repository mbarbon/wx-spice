package Devel::ebug::Wx::Service::Base;

use strict;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(initialized finalized) );

sub abstract { __PACKAGE__ eq $_[0] }

# empty base implementations
sub initialize { my( $self, $wxebug ) = @_; }
sub load_state { my( $self ) = @_; }
sub save_state { my( $self ) = @_; }
sub finalize   { my( $self ) = @_; }

1;
