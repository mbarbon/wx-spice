package Devel::ebug::Wx::Command::ShowFile;

use strict;
use Wx::Spice::Plugin qw(:plugin);

use Wx qw(:id);

sub commands : MenuCommand {
    return
      ( view_menu => { tag      => 'view',
                       label    => 'View',
                       priority => 500,
                      },
        showfile  => { sub      => \&show_file,
	               menu     => 'view',
                       label    => 'Show file',
                       priority => 100,
                       },
        );
}

sub show_file {
    my( $sm ) = @_;
    my $files = [ $sm->ebug_publisher_service->filenames ];
    my $dlg = Wx::SingleChoiceDialog->new
      ( $sm->ebug_wx_service, "File to display", "Choose a file", $files );

    if( $dlg->ShowModal == wxID_OK ) {
        $sm->code_display_service->show_code_for_file( $dlg->GetStringSelection );
    }

    $dlg->Destroy;
}

1;
