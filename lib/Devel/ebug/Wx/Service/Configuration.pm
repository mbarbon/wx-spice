package Devel::ebug::Wx::Service::Configuration;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);

__PACKAGE__->mk_ro_accessors( qw() );

sub service_name { 'configuration' }
sub initialized  { 1 }
sub finalized    { 0 }

sub new {
    my( $class, $wxebug ) = @_;

    return $class;
}

sub get_config {
    my( $class, $section ) = @_;

    my $cfg = Wx::ConfigBase::Get;
    # FIXME validate
    $cfg->SetPath( "/$section" );

    return $cfg;
}

1;
