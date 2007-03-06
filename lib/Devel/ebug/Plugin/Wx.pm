package Devel::ebug::Plugin::Wx;

use strict;
use base qw(Exporter);

our @EXPORT = qw(break_points_file all_break_points stack_trace_folded);

# list break points
sub all_break_points {
    my( $self ) = @_;
    my $response = $self->talk( { command  => "all_break_points" } );
    return @{$response->{break_points}};
}

sub break_points_file {
    my( $self, $filename ) = @_;
    my $response = $self->talk
      ( { command  => "break_points_file",
          filename => $filename,
          } );
    return @{$response->{break_points}};
}

sub _frame { 'Devel::ebug::Plugin::Wx::StackTraceFrame' }

# folds current/caller frame in every item, includes main and
# current frame
sub stack_trace_folded {
    my( $self ) = @_;
    my @frames = $self->stack_trace;
    my @folded = map _frame->new_from_frame( $_ ), @frames;

    # main
    push @folded, _frame->new
      ( { current_package    => @frames ? $frames[-1]->package  : undef,
          current_filename   => @frames ? $frames[-1]->filename : undef,
          current_line       => @frames ? $frames[-1]->line     : undef,
          current_subroutine => 'MAIN::',
          args               => [],
          } );
    # current
    if( @folded ) {
        $folded[0]->{current_package} = $self->package;
        $folded[0]->{current_filename} = $self->filename;
        $folded[0]->{current_line} = $self->line;
    } else {
        $folded[0] = _frame->new
          ( { current_package    => $self->package,
              current_filename   => $self->filename,
              current_line       => $self->line,
              current_subroutine => 'MAIN::',
              } );
    }

    # propagate current_* down the call chain
    for( my $i = 1; $i < @folded; ++$i ) {
        $folded[$i]->{current_package} = $folded[$i-1]->caller_package;
        $folded[$i]->{current_filename} = $folded[$i-1]->caller_filename;
        $folded[$i]->{current_line} = $folded[$i-1]->caller_line;
    }

    # propagate caller_subroutine up the call chain
    for( my $i = @folded - 1; $i > 0; --$i ) {
        $folded[$i-1]->{caller_subroutine} = $folded[$i]->current_subroutine;
    }

    return @folded;
}

package Devel::ebug::Plugin::Wx::StackTraceFrame;

use strict;
use base qw(Devel::StackTraceFrame Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors
  ( qw(caller_package current_package caller_subroutine current_subroutine
       caller_filename current_filename caller_line current_line) );

sub new {
    my( $class, $args ) = @_;
    my $self = bless { %$args }, $class;

    return $self;
}

sub new_from_frame {
    my( $class, $frame ) = @_;
    my $self = bless { %$frame }, $class;

    $self->{current_subroutine} = $self->{subroutine};
    $self->{caller_package} = $self->{package};
    $self->{caller_filename} = $self->{filename};
    $self->{caller_line} = $self->{line};

    return $self;
}

1;
