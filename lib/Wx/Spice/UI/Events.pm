package Wx::Spice::UI::Events;

use strict;
use Exporter; *import = \&Exporter::import;

use Wx;
use Wx::Event qw(EVT_BUTTON EVT_MENU EVT_UPDATE_UI);

our @EXPORT_OK = qw(EVT_SPICE_BUTTON EVT_SPICE_MENU EVT_SPICE_UPDATE_UI
                    EVT_SPICE_UPDATE_UI_ENABLE);

sub EVT_SPICE_MENU($$$$) {
    my $cm = $_[2]->command_manager_service;
    EVT_MENU( $_[0], $_[1], $cm->get_command_sender( $_[3], $_[2] ) );
}

sub EVT_SPICE_BUTTON($$$$) {
    my $cm = $_[2]->command_manager_service;
    EVT_BUTTON( $_[0], $_[1], $cm->get_command_sender( $_[3], $_[2] ) );
}

sub EVT_SPICE_UPDATE_UI($$$$) {
    my( $sm, $sub ) = ( $_[2], $_[3] );
    my $update_ui = sub { $sub->( $sm, $_[1] ) };
    EVT_UPDATE_UI( $_[0], $_[1], $update_ui );
}

sub EVT_SPICE_UPDATE_UI_ENABLE($$$$) {
    my( $cm, $command ) = ( $_[2]->command_manager_service, $_[3] );
    my $update_ui = sub {
        $_[1]->Enable( $cm->command_active( $command ) );
    };
    EVT_UPDATE_UI( $_[0], $_[1], $update_ui );
}

1;
