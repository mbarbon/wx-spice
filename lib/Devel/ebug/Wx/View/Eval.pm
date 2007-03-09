package Devel::ebug::Wx::View::Eval;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);

__PACKAGE__->mk_accessors( qw(display input display_mode) );

use Wx qw(:textctrl :sizer);
use Wx::Event qw(EVT_BUTTON);

sub tag         { 'eval' }
sub description { 'Eval' }

sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->SetSize( 300, 200 ); # FIXME absolute sizing sucks
    $self->wxebug( $wxebug );
    $self->{input} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1,-1],
                                        wxTE_MULTILINE );
    $self->{display} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1, -1],
                                        wxTE_MULTILINE );
    $self->{display_mode} = Wx::Choice->new( $self, -1 );

    $self->display_mode->Append( @$_ )
      foreach [ 'YAML', 'use YAML; Dump(%s)' ],
              [ 'Data::Dumper', 'use Data::Dumper; Dumper(%s)' ],
              [ 'Plain', '%s' ];
    $self->display_mode->SetSelection( 0 ); # FIXME save last
    my $eval = Wx::Button->new( $self, -1, 'Eval' );
    my $clear_eval = Wx::Button->new( $self, -1, 'Clear eval' );
    my $clear_result = Wx::Button->new( $self, -1, 'Clear result' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $b  = Wx::BoxSizer->new( wxHORIZONTAL );
    $sz->Add( $self->input, 1, wxGROW );
    $sz->Add( $self->display, 1, wxGROW );
    $b->Add( $eval, 0, wxALL, 2 );
    $b->Add( $clear_eval, 0, wxALL, 2 );
    $b->Add( $clear_result, 0, wxALL, 2 );
    $b->Add( $self->display_mode, 1, wxALL, 2 );
    $sz->Add( $b, 0, wxGROW );
    $self->SetSizer( $sz );

    $self->register_view;

    EVT_BUTTON( $self, $eval, sub { $self->_eval } );
    EVT_BUTTON( $self, $clear_eval, sub { $self->input->Clear } );
    EVT_BUTTON( $self, $clear_result, sub { $self->display->Clear } );

    return $self;
}

sub _eval {
    my( $self ) = @_;

    my $mode = $self->display_mode->GetClientData
                   ( $self->display_mode->GetSelection );
    my $expr = $self->input->GetValue;
    my $v = $self->ebug->eval( sprintf $mode, $expr ) || "";
    $self->display->WriteText( $v );
}

1;
