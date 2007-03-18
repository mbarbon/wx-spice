package Devel::ebug::Plugin::Wx;

use strict;
use base qw(Exporter);

our @EXPORT = qw(break_points_file all_break_points);

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

1;
