package Devel::ebug::Wx::Service::CommandManager;

use strict;
use base qw(Wx::Spice::Service::Base);
use Wx::Spice::Plugin qw(:manager :plugin);
use Wx::Spice::ServiceManager::Holder;
use Wx::Spice::Service::CommandManager;

load_plugins( search_path => 'Devel::ebug::Wx::Command' );

__PACKAGE__->mk_accessors( qw(key_map _menu_tree) );

use Wx qw(:menu);
use Wx::Spice::UI::Events qw(EVT_SPICE_MENU EVT_SPICE_UPDATE_UI
                             EVT_SPICE_UPDATE_UI_ENABLE);

sub service_name : Service { 'menu_command_manager' }

sub initialize {
    my( $self, $manager ) = @_;

    ( $self->{key_map}, $self->{_menu_tree} ) = $self->_setup_commands;
}

sub get_menu_bar {
    my( $self, $window ) = @_;

    return $self->_build_menu( $window, $self->_menu_tree );
}

sub _build_menu {
    my( $self, $window, $menu_tree ) = @_;

    my $mbar = Wx::MenuBar->new;
    my $sm = $self->service_manager;

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
            EVT_SPICE_MENU( $window, $mitem, $sm, $item->{id} );
            my $update = $item->{update_menu};
            if( $update && $update eq 'enable' ) {
                EVT_SPICE_UPDATE_UI_ENABLE( $window, $mitem, $sm, $item->{id} );
            } elsif( $update && ref( $update ) && ref( $update ) eq 'CODE' ) {
                EVT_SPICE_UPDATE_UI( $window, $mitem, $sm, $update );
            }
            $prev_pri = $item->{priority};
        }
        $mbar->Append( $menu, $rv->{label} );
    }

    return $mbar;
}

sub _setup_commands {
    my( $self ) = @_;
    my( %key_map, %menu_tree, %cmds );

    # FIXME: duplicates?
    %cmds = map $_->( $self->service_manager ),
                Wx::Spice::Plugin->menucommands;
    my $cm = $self->command_manager_service;
    foreach my $id ( grep !$cmds{$_}{id}, keys %cmds ) {
        $cm->add_command( $id, $cmds{$id} );
    }
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
                                                        id       => $id,
                                                        %{$cmds{$id}},
                                                        };
    }

    return ( \%key_map, \%menu_tree );
}

sub handle_key {
    my( $self, $code ) = @_;
    my $char = chr( $code );

    if( my $cmd = $self->key_map->{$char} ) {
        $cmd->{sub}->( $self->service_manager );
    }
}

1;
