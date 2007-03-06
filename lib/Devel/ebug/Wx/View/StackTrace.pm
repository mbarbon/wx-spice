package Devel::ebug::Wx::View::StackTrace;

use strict;
use base qw(Wx::ListBox Devel::ebug::Wx::View::Base);

use File::Basename;

use Wx qw(:sizer);
use Wx::Event qw(EVT_LISTBOX EVT_CLOSE);

sub tag         { 'stack' }
sub description { 'Stack' }

sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->SetSize( 300, 400 ); # FIXME: absolute sizing is bad

    $self->wxebug( $wxebug );
    $self->set_stacktrace if $self->ebug->line;

    $self->subscribe_ebug( 'state_changed', sub { $self->_read_stack( @_ ) } );
    $self->register_view;

    EVT_LISTBOX( $self, $self, \&_lbox_click );

    return $self;
}

# should try and be smart and not do a full refresh...
sub _read_stack {
    my( $self, $ebug, $event, %params ) = @_;

    $self->set_stacktrace;
}

sub _lbox_click {
    my( $self, $e ) = @_;
    return unless $e->IsSelection; # skip deselections
    my $to = $e->GetClientData;

    $self->wxebug->code_display_service
         ->highlight_line( $to->[0], $to->[1] );
}

# FIXME incremental read of stacktrace
sub set_stacktrace {
    my( $self ) = @_;
    my @frames = $self->ebug->stack_trace_folded;
    $self->Clear;
    foreach my $frame ( @frames ) {
        my $string = sprintf '%s: %d %s(%s)',
                         basename( $frame->current_filename ),
                         $frame->current_line,
                         $frame->current_subroutine,
                         join ', ', $frame->args;
        $self->Append( $string, [ $frame->current_filename,
                                  $frame->current_line,
                                  ] );
    }
}

1;
