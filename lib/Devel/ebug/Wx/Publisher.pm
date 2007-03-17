package Devel::ebug::Wx::Publisher;

use strict;
use base qw(Class::Accessor::Fast Class::Publisher);

__PACKAGE__->mk_ro_accessors( qw(ebug argv) );
__PACKAGE__->mk_accessors( qw(_line _sub _package _file) );

use Devel::ebug;

sub new {
    my( $class, $ebug ) = @_;
    $ebug ||= Devel::ebug->new;
    my $self = $class->SUPER::new( { ebug     => $ebug,
                                     _package => '',
                                     _line    => -1,
                                     _sub     => '',
                                     _file    => '',
                                     } );

    return $self;
}

sub DESTROY {
    my ( $self ) = @_;
    $self->delete_all_subscribers;
    $self->SUPER::DESTROY;
}

# FIXME: does not scale when additional ebug plugins are loaded
#        maybe needs another level of plugins :-(
my %no_notify =
   map { $_ => 1 }
       qw(program line subroutine package filename codeline
          filenames break_points codelines pad finished
          is_running);

my %must_be_running =
   map { $_ => 1 }
       qw(step next run return);

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    ( my $sub = $AUTOLOAD ) =~ s/.*:://;
    return if $must_be_running{$sub} && !$self->is_running;
    if( wantarray ) {
        my @res = $self->ebug->$sub( @_ );

        $self->_notify_basic_changes unless $no_notify{$sub};
        return @res;
    } else {
        my $res = $self->ebug->$sub( @_ );

        $self->_notify_basic_changes unless $no_notify{$sub};
        return $res;
    }
}

sub is_running {
    my( $self ) = @_;

    return $self->argv && !$self->ebug->finished;
}

sub load_program {
    my( $self, $argv ) = @_;
    $self->{argv} = $argv || $self->{argv} || [];
    my $filename = join ' ', @{$self->argv};

    unless ($filename) {
        $filename = '-e "Interactive ebugging shell"';
    }

    $self->ebug->program( $filename );
    $self->ebug->load;

    $self->_notify_breakpoint_changes( 'load_program',
                                       argv      => $self->argv,
                                       filename  => $filename,
                                       );
    $self->_notify_basic_changes;
}

sub break_point {
    my( $self, $file, $line, $condition ) = @_;
    return unless $self->is_running;
    my $res = $self->ebug->break_point( $file, $line, $condition );

    return unless $res->{line};
    $self->_notify_breakpoint_changes( 'break_point',
                                       file      => $file,
                                       line      => $res->{line},
                                       condition => $condition,
                                       );
}

sub break_point_delete {
    my( $self, $file, $line ) = @_;
    return unless $self->is_running;
    $self->ebug->break_point_delete( $file, $line );

    $self->_notify_breakpoint_changes( 'break_point_delete',
                                       file  => $file,
                                       line  => $line,
                                       );
}

sub _notify_breakpoint_changes {
    my( $self, $event, %args ) = @_;

    $self->notify_subscribers( $event, %args );
}

sub _notify_basic_changes {
    my( $self ) = @_;
    my $ebug = $self->ebug;

    if( $ebug->finished ) {
        $self->notify_subscribers( 'finished' );
        return;
    }

    my $file_changed = $self->_file ne $ebug->filename;
    my $line_changed = $self->_line ne $ebug->line;
    my $sub_changed  = $self->_sub ne $ebug->subroutine;
    my $pack_changed = $self->_package ne $ebug->package;
    my $any_changed  = $file_changed || $line_changed ||
                       $sub_changed || $pack_changed;

    # must do it here or we risk infinite recursion
    $self->_file( $ebug->filename );
    $self->_line( $ebug->line );
    $self->_sub( $ebug->subroutine );
    $self->_package( $ebug->package );

    $self->notify_subscribers( 'file_changed',
                               old_file    => $self->_file,
                               )
      if $file_changed;
    $self->notify_subscribers( 'line_changed',
                               old_line    => $self->_line,
                               )
      if $line_changed;
    $self->notify_subscribers( 'sub_changed',
                               old_sub     => $self->_sub,
                               )
      if $sub_changed;
    $self->notify_subscribers( 'package_changed',
                               old_package => $self->_package,
                               )
      if $pack_changed;
    $self->notify_subscribers( 'state_changed',
                               old_file    => $self->_file,
                               old_line    => $self->_line,
                               old_sub     => $self->_sub,
                               old_package => $self->_package,
                               )
      if $any_changed;
}

1;
