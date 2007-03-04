package Devel::ebug::Backend::Plugin::Wx;

use strict;
use warnings;

use Devel::ebug::Backend::Plugin::ActionPoints;

sub register_commands {
    return
      ( break_points_file => { sub => \&break_points_file },
        );
}

sub break_points_file {
    my( $req, $context ) = @_;
    use vars qw(@dbline %dbline);
    *DB::dbline = $main::{ '_<' . $req->{filename} };
    my $break_points =
      [ map { [ $_, $DB::dbline{$_} ] }
        sort { $a <=> $b }
        grep { $DB::dbline{$_} }
        keys %DB::dbline
        ];
    return { break_points => $break_points };
}

# FIXME: this is nasty, but works as a temporary measure
package Devel::ebug::Backend::Plugin::ActionPoints;

use strict;
no warnings 'redefine';

sub set_break_point {
  my($filename, $line, $condition) = @_;
  $condition ||= 1;
  *DB::dbline = $main::{ '_<' . $filename };

  # move forward until a line we can actually break on
  while (1) {
    return 0 if not defined $DB::dbline[$line]; # end of code
    last unless $DB::dbline[$line] == 0; # not breakable
    $line++;
  }
  $DB::dbline{$line} = $condition;
  return $line;
}

sub break_point {
  my($req, $context) = @_;
  my $line = set_break_point($req->{filename}, $req->{line}, $req->{condition});
  return $line ? { line => $line } : {};
}

1;
