package Devel::ebug::Wx::Command::Standard;

use strict;

use Wx qw(wxOK wxVERSION_STRING);

sub register_commands {
    return
      ( file_menu => { tag      => 'file',
                       label    => 'File',
                       priority => 0,
                       },
        help_menu => { tag      => 'help',
                       label    => 'Help',
                       priority => 10000,
                       },
        quit      => { sub   => \&quit,
                       menu  => 'file',
                       label => 'Exit',
                       },
        about     => { sub   => \&about,
                       menu  => 'help',
                       label => 'About...',
                       },
        );
}

sub quit {
    my( $wx ) = @_;

    $wx->Close;
}

sub about {
    my( $wx ) = @_;

    Wx::MessageBox( "wxebug, (c) 2007 Mattia Barbon\n" .
                    "wxPerl $Wx::VERSION, " . wxVERSION_STRING,
                    "About wxebug", wxOK, $wx );
}

1;
