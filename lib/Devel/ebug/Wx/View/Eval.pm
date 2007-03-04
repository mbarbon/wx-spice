package Devel::ebug::Wx::View::Eval;

# FIXME: need to kill the cruft below and build a real eval window

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);

__PACKAGE__->mk_accessors( qw(display input) );

use Wx qw(:textctrl :sizer);
use Wx::Event qw(EVT_TEXT_ENTER);

sub tag         { 'eval' }
sub description { 'Eval' }

sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->SetSize( 300, 200 );

    $self->wxebug( $wxebug );

    $self->{display} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1, 150],
                                        wxTE_MULTILINE|wxTE_READONLY );
    $self->{input} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1,-1],
                                        wxTE_PROCESS_ENTER );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    $sz->Add( $self->display, 1, wxGROW );
    $sz->Add( $self->input, 0, wxGROW );
    $self->SetSizer( $sz );

    EVT_TEXT_ENTER( $self, $self->input, sub { $self->DoCommand } );

    return $self;
}

sub print {
    my( $self, $string ) = @_;

    $self->display->WriteText( $string );
}

my $last_command = "s";

sub DoCommand {
    my $self = shift;
    my $ebug = $self->ebug;

    if ($ebug->finished) {
      $self->print( "ebug: Program finished. Enter 'restart' or 'q'\n" );
    }

    my $command = $self->input->GetValue;
    $self->input->Clear;
    $command = "q" if not defined $command;
    $command = $last_command if ($command eq "");

    if ($command =~ /[?h]/) {
      $self->print( 'Commands:
      
      b Calc::fib)
      e Eval Perl code and print the result (eg: e $x+$y)
      o Output (show STDOUT, STDERR)
      p Show pad
    art Restart the program
      u Undo (eg: u, u 4)
      w Set a watchpoint (eg: w $t > 10)
      x Dump a variable using YAML (eg: x $object)
    ');
    } elsif ($command eq 'p') {
      my $pad = $ebug->pad_human;
      foreach my $k (sort keys %$pad) {
        my $v = $pad->{$k};
        $self->print( "  $k = $v;\n" );
      }
    } elsif ($command eq 'o') {
      my($stdout, $stderr) = $ebug->output;
      $self->print( "STDOUT:\n$stdout\n" );
      $self->print( "STDERR:\n$stderr\n" );
    } elsif ($command eq 'restart') {
      $ebug->load;
    } elsif ($command =~ /^ret ?(.*)/) {
      $ebug->return($1);
    } elsif ($command =~ /^b (.+)/) {
      $ebug->break_point_subroutine($1);
    } elsif ($command =~ /^w (.+)/) {
      my($watch_point) = $command =~ /^w (.+)/;
      $ebug->watch_point($watch_point);
    } elsif ($command =~ /^x (.+)/) {
      my $v = $ebug->eval("use YAML; Dump($1)") || "";
      $self->print( "$v\n" );
    } elsif ($command =~ /^e (.+)/) {
      my $v = $ebug->eval($1) || "";
      $self->print( "$v\n" );
    } elsif ($command) {
      my $v = $ebug->eval($command) || "";
      $self->print( "$v\n" );
    }
    $last_command = $command;
}

1;
