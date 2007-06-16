package Wx::Spice::Service::CommandManager;

use strict;
use base qw(Wx::Spice::Service::Base);
use Wx::Spice::Plugin qw(:manager :plugin);
use Wx::Spice::ServiceManager::Holder;

__PACKAGE__->mk_accessors( qw(commands) );

sub service_name : Service { 'command_manager' }

sub new {
    return shift->SUPER::new( { commands => {} } );
}

sub initialize {
    my( $self ) = @_;

    # FIXME: duplicates?
    my %cmds = map $_->( $self->service_manager ),
                   Wx::Spice::Plugin->commands;
    $self->{commands} = \%cmds;
}

sub send_command {
    my( $self, $command, @args ) = @_;

    if( my $cmd = $self->commands->{$command} ) {
        $cmd->{sub}->( $self->service_manager, @args );
    }
}

sub command_active {
    my( $self, $command ) = @_;

    if( my $cmd = $self->commands->{$command} ) {
        return 1 unless $cmd->{active};
        return $cmd->{active}->( $self->service_manager ) ? 1 : 0;
    }

    return 0;
}

sub get_command_sender {
    my( $self, $command, @args ) = @_;

    return sub { $self->send_command( $command, @args ) };
}

1;
