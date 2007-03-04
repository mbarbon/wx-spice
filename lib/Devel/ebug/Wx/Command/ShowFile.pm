package Devel::ebug::Wx::Command::ShowFile;

use strict;

use Wx qw(:id);

sub register_commands {
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
    my( $wx ) = @_;
    my $files = [ $wx->ebug->filenames ];
    my $dlg = Wx::SingleChoiceDialog->new
      ( $wx, "File to display", "Choose a file", $files );

    if( $dlg->ShowModal == wxID_OK ) {
        $wx->code->show_code_for_file( $dlg->GetStringSelection );
    }

    $dlg->Destroy;
}

1;
