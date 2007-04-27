package Devel::ebug::Wx::Service::Configuration;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

=head1 NAME

Devel::ebug::Wx::Service::Configuration - manage ebugger configuration

=head1 SYNOPSIS

  my $cm = ...->get_service( 'configuration' );
  my $cfg = $cm->get_config( 'service_name' );

  my $value_or_default = $cfg->get_value( 'value_name', $value_default );
  $cfg->set_value( 'value_name', $value );
  $cfg->delete_value( 'value_name' );

=head1 DESCRIPTION

The C<configuration> service manages the global configuration for all
services.

=head1 METHODS

=cut

__PACKAGE__->mk_ro_accessors( qw(inifile) );

use File::UserConfig;
use Config::IniFiles;
use File::Spec;

sub service_name : Service { 'configuration' }
sub initialized  { 1 }
sub finalized    { 0 }

sub file_name {
    my( $class ) = @_;
    my $dir = File::UserConfig->new( dist     => 'ebug_wx',
                                     sharedir => '.',
                                     )->configdir;

    return File::Spec->catfile( $dir, 'ebug_wx.ini' );
}

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new;
    my $file = $class->file_name;

    if( -f $file ) {
        $self->{inifile} = Config::IniFiles->new( -file => $file );
    } else {
        $self->{inifile} = Config::IniFiles->new;
        $self->inifile->SetFileName( $file );
    }

    return $self;
}

=head2 get_config

  my $cfg = $cm->get_config( 'service_name' );

  my $value_or_default = $cfg->get_value( 'value_name', $value_default );
  $cfg->set_value( 'value_name', $value );
  $cfg->delete_value( 'value_name' );
  $cfg->get_serialized_value( 'value_name', $default );
  $cfg->set_serialized_value( 'value_name', $value );

Returns an object that can be used to read/change/delete the value of
the configuration keys for a given service.

=cut

sub get_config {
    my( $self, $section ) = @_;

    return Devel::ebug::Wx::Service::Configuration::My->new( $self->inifile,
                                                             $section );
}

sub finalize {
    my( $self ) = @_;

    $self->inifile->RewriteConfig if $self->inifile;
}

package Devel::ebug::Wx::Service::Configuration::My;

use strict;
use base qw(Class::Accessor::Fast);
use YAML qw();

__PACKAGE__->mk_ro_accessors( qw(inifile section) );

sub new {
    my( $class, $inifile, $section ) = @_;
    my $self = $class->SUPER::new
      ( { inifile   => $inifile,
          section   => $section,
          } );

    return $self;
}

sub get_value {
    my( $self, $name, $default ) = @_;

    return $self->inifile->val( $self->section, $name, $default );
}

sub set_value {
    my( $self, $name, @values ) = @_;

    unless( $self->inifile->setval( $self->section, $name, @values ) ) {
        $self->inifile->newval( $self->section, $name, @values );
    }

    return;
}

sub set_serialized_value {
    my( $self, $name, $value ) = @_;

    $self->set_value( $name, YAML::Dump( $value ) );
}

sub get_serialized_value {
    my( $self, $name, $default ) = @_;

    my @values = $self->get_value( $name, undef );
    return $default unless @values;
    my $undumped = eval {
        YAML::Load( join "\n", @values, '' );
    };

    return $@ ? $default : $undumped;
}

sub delete_value {
    my( $self, $name ) = @_;

    $self->inifile->delval( $self->section, $name );
}

1;
