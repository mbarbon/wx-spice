package Devel::ebug::Wx;

use Wx;

use strict;
use warnings;
use base qw(Wx::Frame Class::Accessor::Fast);

our $VERSION = '0.02';

use Wx qw(:aui);
use Wx::AUI;
use Wx::Event qw(EVT_CLOSE EVT_MENU);

use Devel::ebug;
use Devel::ebug::Wx::View::Code::STC;
use Devel::ebug::Wx::Publisher;

use Module::Pluggable
      sub_name    => 'commands',
      search_path => 'Devel::ebug::Wx::Command',
      require     => 1;

__PACKAGE__->mk_ro_accessors( qw(code ebug key_map manager pane_info) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( undef, -1, 'wxebug', [-1, -1], [-1, 500] );

    $self->{ebug} = Devel::ebug::Wx::Publisher->new( Devel::ebug->new );
    $self->{code} = Devel::ebug::Wx::View::Code::STC->new( $self, $self );
    $self->{manager} = Wx::AuiManager->new;
    $self->manager->SetManagedWindow( $self );

    $self->{pane_info} = Wx::AuiPaneInfo->new
        ->CenterPane->TopDockable->BottomDockable->LeftDockable->RightDockable
        ->Floatable->Movable->PinButton->CaptionVisible->Resizable
        ->CloseButton->DestroyOnClose;
    $self->manager->AddPane
      ( $self->code, $self->pane_info->Name( 'source_code' )
        ->Caption( 'Code' ) );

    $self->ebug->add_subscriber( 'load_program', sub { $self->_pgm_load( @_ ) } );

    $self->ebug->load_program( $args->{argv} );

    EVT_CLOSE( $self, sub { $self->Destroy } );

    my( $key_map, $menu_tree ) = $self->_setup_commands;
    $self->_build_menu( $menu_tree );
    $self->{key_map} = $key_map;

    $self->manager->Update;

    return $self;
}

sub _pgm_load {
    my( $self, $ebug, $event, %params ) = @_;

    $self->SetTitle( $params{filename} );
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
            EVT_MENU( $self, $menu->Append( -1, $label ),
                      $item->{sub} );
            $prev_pri = $item->{priority};
        }
        $mbar->Append( $menu, $rv->{label} );
    }

    $self->SetMenuBar( $mbar );
}

sub _setup_commands {
    my( $self ) = @_;
    my @commands = $self->commands;
    my( %key_map, %menu_tree, %cmds );

    # FIXME: duplicates?
    %cmds = map $_->register_commands,
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
        $cmd->{sub}->( $self );
    }
}

1;

__END__

=head1 NAME

Devel::ebug::Wx - GUI interface for your (d)ebugging needs

=head1 SYNOPSIS

  # it's easier to use the 'ebug_wx' script
  my $app = Wx::SimpleApp->new;
  my $wx = Devel::ebug::Wx->new( { argv => \@ARGV } );
  $wx->Show;
  $app->MainLoop;

=head1 DESCRIPTION

L<Devel::ebug::Wx> is a GUI front end to L<Devel::ebug>.

The core is a publisher/subscriber wrapper around L<Devel::ebug>
(L<Devel::ebug::Wx::Publisher>) plus a plugin system for defining menu
commands and keyboard bindings (L<Devel::ebug::Wx::Command::*>) and
views (L<Devel::ebug::Wx::View::*>).

The wxWidgets Advanced User Interface is used, so it is possible
to dock/undock and arrange views.

=head1 TODO

=over 4

=item * make a saner interface for plugins (esp. commands)

=item * define a service interface (for example for code-viewing, configuration)

=item * add more views (variable watch, data structure display)

=item * save GUI status between sessions, optionally save the whole debugger status

=item * handle the cases when the program is terminated

=item * see the FIXMEs

=back

=head1 SEE ALSO

L<Devel::ebug>, L<ebug_wx>, L<Wx>, L<ebug>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.
