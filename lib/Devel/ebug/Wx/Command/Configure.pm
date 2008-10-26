package Devel::ebug::Wx::Command::Configure;

use strict;
use Wx::Spice::Plugin qw(:plugin);

sub command : MenuCommand {
    my( $class, $sm ) = @_;

    return ( 'configure',
             { sub         => \&_configure,
               menu        => 'view',
               label       => 'Configure',
               priority    => 600,
               },
             );
}

sub _configure {
    my( $sm ) = @_;
    my $cm = $sm->configuration_manager_service;
    $cm->show_configuration( $sm->ebug_wx_service );
}

1;
