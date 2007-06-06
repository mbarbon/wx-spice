package Devel::ebug::Wx::Service::Configuration;

use strict;
use base qw(Wx::Spice::Service::Configuration::Base);
use Wx::Spice::Plugin qw(:plugin);

=head1 NAME

Devel::ebug::Wx::Service::Configuration - manage ebugger configuration

=head1 DESCRIPTION

The C<configuration> service manages the global configuration for all
services.

=head1 METHODS

=cut

sub service_name : Service { 'configuration' }

sub directory_name { 'ebug_wx' }
sub file_name      { 'ebug_wx.ini' }

1;
