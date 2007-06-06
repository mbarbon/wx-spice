package Wx::Spice::Service::Configuration::Base;

use strict;
use base qw(Wx::Spice::Service::Base);
use Wx::Spice::Plugin qw(:plugin);

=head1 NAME

Wx::Spice::Service::Configuration::Base - manage configuration for components

=head1 SYNOPSIS

  # define the configuration service
  package MyApp::Service::Configuration;

  use strict;
  use base qw(Wx::Spice::Service::Configuration::Base);
  use Wx::Spice::Plugin qw(:plugin);

  sub service_name : Service { 'configuration' }

  sub directory_name { 'my_app' }
  sub file_name      { 'global.ini' }

  # in other parts of the program
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

__PACKAGE__->mk_ro_accessors( qw(inifiles default_file) );

use File::UserConfig;
use Config::IniFiles;
use File::Spec;

sub initialized  { 1 }
sub finalized    { 0 }

sub file_path {
    my( $class ) = @_;
    my $dir = File::UserConfig->new( dist     => $class->directory_name,
                                     sharedir => '.',
                                     )->configdir;

    return File::Spec->catfile( $dir, $class->file_name );
}

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( { inifiles => {} } );

    $self->{default_file} = $class->file_path;
    _load_inifile( $self, $self->default_file );

    return $self;
}

sub _read_or_create {
    my( $file ) = @_;

    if( -f $file ) {
        return Config::IniFiles->new( -file => $file );
    } else {
        my $inifile = Config::IniFiles->new;
        $inifile->SetFileName( $file );

        return $inifile;
    }
}

sub _load_inifile {
    my( $self, $file_name ) = @_;

    $self->inifiles->{$file_name} ||= _read_or_create( $file_name );
}

=head2 get_config

  my $cfg = $cm->get_config( 'service_name' );
  my $cfg2 = $cm->get_config( 'service_name', 'myfile.ini' );

  my $value_or_default = $cfg->get_value( 'value_name', $value_default );
  $cfg->set_value( 'value_name', $value );
  $cfg->delete_value( 'value_name' );
  $cfg->get_serialized_value( 'value_name', $default );
  $cfg->set_serialized_value( 'value_name', $value );

  # force file rewrite
  $cm->flush( 'myfile.ini' );

Returns an object that can be used to read/change/delete the value of
the configuration keys for a given service.

=cut

sub get_config {
    my( $self, $section, $filename ) = @_;

    return Wx::Spice::Service::Configuration::My->new
      ( _load_inifile( $self, $filename || $self->default_file ), $section );
}

sub finalize {
    my( $self ) = @_;

    $_->RewriteConfig foreach values %{$self->inifiles};
}

sub flush {
    my( $self, $file ) = @_;

    $self->inifiles->{$file}->RewriteConfig if $self->inifiles->{$file};
}

package Wx::Spice::Service::Configuration::My;

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
