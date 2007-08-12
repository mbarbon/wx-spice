package Devel::ebug::Wx::Service::RemoteDebugger;

use strict;
use base qw(Wx::Spice::Service::Base);
use Wx::Spice::Plugin qw(:plugin);
use Wx::Spice::ServiceManager::Holder;

__PACKAGE__->mk_accessors( qw(socket key) );

use Wx::Socket;
use Wx qw(:socket);
use Wx::Event qw(EVT_SOCKET_CONNECTION);

sub service_name : Service { 'remote_debugger' }

sub compute_key {
    my( $self, $port ) = @_;
    my $k = String::Koremutake->new;
    my $rand = int( rand( 100_000 ) );
    $rand = $rand - ( $rand % 1024 ) + ( $port - 3141 ) % 1024;

    return $k->integer_to_koremutake( $rand );
}

sub compute_port {
    my( $self, $key ) = @_;
    my $k = String::Koremutake->new;

    return 3141 + ( $k->koremutake_to_integer( $key ) % 1024 );
}

sub port { $_[0]->compute_port( $_[0]->key ) }
sub is_listening { $_[0]->socket ? 1 : 0 }

sub start_server {
    my( $self ) = @_;

    return if $self->is_listening;
    my $sock = Wx::SocketServer->new( 'localhost', $self->port,
                                      wxSOCKET_WAITALL|8 );

    my $on_connect = sub {
        my( $sock, undef, $evt ) = @_;
        my $client = $sock->Accept( 0 );

        my $ebug = Devel::ebug::Wx::Service::RemoteDebugger::ebug->new
                       ( { key    => $self->key,
                           } );
        $ebug->set_wx_socket( $client );
        $self->ebug_publisher_service->set_ebug( $ebug, [ 'remote', 'ebugger' ] );
    };

    $self->socket( $sock );
    EVT_SOCKET_CONNECTION( $self->ebug_wx_service, $sock, $on_connect ) ;
}

sub stop_server {
    my( $self ) = @_;

    return unless $self->is_listening;
    EVT_SOCKET_CONNECTION( $self->ebug_wx_service, $self->socket, undef ) ;
    $self->socket->Destroy;
    $self->socket( undef );
}

package Devel::ebug::Wx::Service::RemoteDebugger::TieWxSocket;

sub TIEHANDLE {
    my( $class, $socket ) = @_;

    return bless { socket => $socket }, $class;
}

sub PRINT {
    $_[0]->{socket}->Write( $_[1] );
}

sub READLINE {
    my $socket = $_[0]->{socket};

    my $res = undef;
    my $buf = '';
    while( $socket->Read( $buf, 1 ) ) {
        $res .= $buf;
        last if $buf eq "\n";
    }

    return $res;
}

package Devel::ebug::Wx::Service::RemoteDebugger::ebug;

use strict;
use base qw(Devel::ebug);

__PACKAGE__->mk_ro_accessors( qw(key) );

use Symbol qw();

sub set_wx_socket {
    my( $self, $client ) = @_;

    my $socket = Symbol::gensym();
    tie *$socket, 'Devel::ebug::Wx::Service::RemoteDebugger::TieWxSocket',
                  $client;

    $self->load_plugins;
    $self->socket( $socket );
    $self->post_connect( $self->key );
}

sub finished {
    my( $self ) = @_;

    return 0 unless $self->socket;
    return 1 if tied( *{$self->socket} )->{socket}->IsDisconnected;
    return 0;
}

package Devel::ebug::Wx::View::RemoteDebugger;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base
            Wx::Spice::Plugin::Configurable::Base);
use Wx::Spice::Plugin qw(:plugin);

__PACKAGE__->mk_accessors( qw(key port) );

use Wx qw(:textctrl :sizer);
use Wx::Event qw(EVT_BUTTON);

sub tag         { 'remote_debugger' }
sub description { 'Remote debugger' }

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    $self->{port} = Wx::TextCtrl->new( $self, -1, 3744 );
    $self->{key} = Wx::TextCtrl->new( $self, -1, "bubre" );

    my $start = Wx::Button->new( $self, -1, 'Start listener' );
    my $stop  = Wx::Button->new( $self, -1, 'Stop listener' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    $sz->Add( $self->port, 0, wxGROW|wxALL, 5 );
    $sz->Add( $self->key, 0, wxGROW|wxALL, 5 );
    $sz->Add( $start, 0, wxGROW|wxALL, 5 );
    $sz->Add( $stop, 0, wxGROW|wxALL, 5 );
    $self->SetSizer( $sz );

    $self->register_view;

    EVT_BUTTON( $self, $start, sub { $self->_start } );
    EVT_BUTTON( $self, $stop,  sub { $self->_stop } );

    $self->SetSize( $self->default_size );

    return $self;
}

sub _start {
    my( $self ) = @_;
    my $port = $self->port->GetValue;
    my $key = $self->key->GetValue;
    my $rd = $self->wxebug->remote_debugger_service;

    my $port_from_key = $rd->compute_port( $key );

    if( $port_from_key != $port ) {
        $key = $rd->compute_key( $port );
    }

    $self->key->SetValue( $key );

    $rd->key( $key );
    $rd->stop_server;
    $rd->start_server;
}

sub _stop {
    my( $self ) = @_;

    $self->wxebug->remote_debugger_service->stop_server;
}

1;
