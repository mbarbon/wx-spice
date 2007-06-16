package Wx::Spice::UI::Events;

use strict;
use Exporter; *import = \&Exporter::import;

use Wx;
use Wx::Event qw(EVT_BUTTON EVT_UPDATE_UI);

our @EXPORT_OK = qw(EVT_SPICE_BUTTON EVT_SPICE_UPDATE_UI);

sub EVT_SPICE_BUTTON($$$$) {
    my $cm = $_[2]->get_service( 'command_manager' );
    EVT_BUTTON( $_[0], $_[1], $cm->get_command_sender( $_[3], $_[2] ) );
}

sub EVT_SPICE_UPDATE_UI($$$$) {
    my( $cm, $command ) = ( $_[2]->get_service( 'command_manager' ), $_[3] );
    my $update_ui = sub {
        $_[1]->Enable( $cm->command_active( $command ) );
    };
    EVT_UPDATE_UI( $_[0], $_[1], $update_ui );
}

1;
