package Devel::ebug::Wx::Service::CodeDisplay;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);

use Devel::ebug::Wx::View::Code::STC;

__PACKAGE__->mk_accessors( qw(code_display) );

sub service_name { 'code_display' }

sub initialize {
    my( $self, $wxebug ) = @_;

    $self->{code_display} = Devel::ebug::Wx::View::Code::STC->new
                                ( $wxebug, $wxebug );
    $wxebug->view_manager_service->create_pane
      ( $self->code_display, { name    => 'source_code',
                               caption => 'Code',
                               } );
}

# forward to view
# FIXME: declare the view as service
sub highlight_line { shift->code_display->highlight_line( @_ ) }
sub show_code_for_file { shift->code_display->show_code_for_file( @_ ) }

1;
