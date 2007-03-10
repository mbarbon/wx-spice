package Devel::ebug::Wx::Service::CommandManager;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);

use Module::Pluggable
      sub_name    => 'commands',
      search_path => 'Devel::ebug::Wx::Command',
      require     => 1,
      except      => qr/::Base$/;

__PACKAGE__->mk_accessors( qw(wxebug key_map _menu_tree) );

use Wx qw(:menu);
use Wx::Event qw(EVT_MENU EVT_UPDATE_UI);

sub service_name { 'command_manager' }

sub initialize {
    my( $self, $wxebug ) = @_;

    $self->{wxebug} = $wxebug;
    ( $self->{key_map}, $self->{_menu_tree} ) = $self->_setup_commands;
}

sub get_menu_bar {
    my( $self ) = @_;

    return $self->_build_menu( $self->_menu_tree );
}

sub _build_menu {
    my( $self, $menu_tree ) = @_;

    my $mbar = Wx::MenuBar->new;

    foreach my $rv ( sort { $a->{priority} <=> $b->{priority} }
                          values %$menu_tree ) {
        my $menu = Wx::Menu->new;
        my $prev_pri = 0;
        foreach my $item ( sort { $a->{priority} <=> $b->{priority} }
                                @{$rv->{childs}} ) {
            if( $prev_pri && $item->{priority} != $prev_pri ) {
                $menu->AppendSeparator;
            }
            my $label = $item->{key} ?
                            sprintf( "%s\t%s", $item->{label}, $item->{key} ) :
                            $item->{label};
            my $style = $item->{checkable} ? wxITEM_CHECK : wxITEM_NORMAL;
            my $mitem = $menu->Append( -1, $label, '', $style );
            EVT_MENU( $self->wxebug, $mitem, $item->{sub} );
            if( $item->{update_menu} ) {
                EVT_UPDATE_UI( $self->wxebug, $mitem, $item->{update_menu} );
            }
            $prev_pri = $item->{priority};
        }
        $mbar->Append( $menu, $rv->{label} );
    }

    return $mbar;
}

sub _setup_commands {
    my( $self ) = @_;
    my @commands = $self->commands;
    my( %key_map, %menu_tree, %cmds );

    # FIXME: duplicates?
    # FIXME: passing $self is hack
    # FIXME allow plugins that are service, command and view
    %cmds = map $_->register_commands( $self->wxebug ),
            grep $_->can( 'register_commands' ),
                 @commands;
    foreach my $id ( grep $cmds{$_}{key}, keys %cmds ) {
        $key_map{$cmds{$id}{key}} = $cmds{$id};
    }
    foreach my $id ( grep $cmds{$_}{tag}, keys %cmds ) {
        $menu_tree{$cmds{$id}{tag}} = { childs   => [],
                                        priority => 0,
                                        %{$cmds{$id}},
                                        };
    }
    foreach my $id ( grep $cmds{$_}{menu}, keys %cmds ) {
        die "Unknown menu: $cmds{$id}{menu}"
          unless $menu_tree{$cmds{$id}{menu}};
        push @{$menu_tree{$cmds{$id}{menu}}{childs}}, { priority => 0,
                                                        %{$cmds{$id}},
                                                        };
    }

    return ( \%key_map, \%menu_tree );
}

sub handle_key {
    my( $self, $code ) = @_;
    my $char = chr( $code );

    if( my $cmd = $self->key_map->{$char} ) {
        $cmd->{sub}->( $self->wxebug );
    }
}

1;
