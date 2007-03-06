package Devel::ebug::Wx::View::Breakpoints;

use strict;
use base qw(Wx::ScrolledWindow Devel::ebug::Wx::View::Base);

__PACKAGE__->mk_accessors( qw(panes sizer) );

use Wx qw(:sizer);

sub tag         { 'breakpoints' }
sub description { 'Breakpoints' }

# FIXME read all breakpoints in constructor, or bad things will happen
sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->SetSize( 300, 200 ); # FIXME: absolute sizing is bad

    $self->wxebug( $wxebug );
    $self->panes( [] );

    $self->subscribe_ebug( 'break_point', sub { $self->_add_bp( @_ ) } );
    $self->subscribe_ebug( 'break_point_delete', sub { $self->_del_bp( @_ ) } );
    $self->register_view;

    my $sizer = Wx::BoxSizer->new( wxVERTICAL );
    $self->SetSizer( $sizer );

    $self->sizer( $sizer );

    return $self;
}

# FIXME ordering and duplicates
sub _add_bp {
    my( $self, $ebug, $event, %params ) = @_;

    my $pane = Devel::ebug::Wx::Breakpoints::Pane->new( $self, \%params );
    push @{$self->panes}, $pane;
    $self->sizer->Add( $pane, 0, wxGROW );
    $self->SetScrollRate( 0, $pane->GetSize->y );
    # force relayout and reset virtual size
    $self->Layout;
    $self->SetSize( $self->GetSize );
}

sub _del_bp {
    my( $self, $ebug, $event, %params ) = @_;

    my $index;
    for( $index = 0; $index < @{$self->panes}; ++$index ) {
        last if    $params{file} eq $self->panes->[$index]->file
                && $params{line} == $self->panes->[$index]->line;
    }
    my $pane = $self->panes->[$index];

    splice @{$self->panes}, $index, 1;
    $self->sizer->Detach( $pane );
    $pane->Destroy;
    # force relayout and reset virtual size
    $self->Layout;
    $self->SetSize( $self->GetSize );
}

sub delete {
    my( $self, $pane ) = @_;

    $self->ebug->break_point_delete( $pane->file, $pane->line );
}

sub go_to {
    my( $self, $pane ) = @_;

    $self->wxebug->code_display_service
         ->highlight_line( $pane->file, $pane->line );
}

sub set_condition {
    my( $self, $pane, $condition ) = @_;

    $self->ebug->ebug->break_point( $pane->file, $pane->line, $condition );
}

package Devel::ebug::Wx::Breakpoints::Pane;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(controls file line) );

use File::Basename qw(basename);

use Wx qw(:sizer);
use Wx::Event qw(EVT_BUTTON EVT_TEXT);

sub new {
    my( $class, $parent, $args ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $bp_label = Wx::StaticText->new( $self, -1, '' );
    my $goto = Wx::Button->new( $self, -1, 'Go to' );
    my $delete = Wx::Button->new( $self, -1, 'Delete' );
    my $cnd_label = Wx::StaticText->new( $self, -1, 'Cond:' );
    my $condition = Wx::TextCtrl->new( $self, -1, '' );

    $self->{controls} = { label     => $bp_label,
                          condition => $condition,
                          };
    $self->{file} = $args->{file};
    $self->{line} = $args->{line};

    $self->display_bp( $args );

    my $topsz = Wx::BoxSizer->new( wxVERTICAL );
    my $fsz = Wx::BoxSizer->new( wxHORIZONTAL );
    my $ssz = Wx::BoxSizer->new( wxHORIZONTAL );

    $fsz->Add( $bp_label, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 2 );
    $fsz->Add( $delete, 0, 0 );
    $fsz->Add( $goto, 0, wxRIGHT, 2 );

    $ssz->Add( $cnd_label, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 2 );
    $ssz->Add( $condition, 1, wxRIGHT, 2 );

    $topsz->Add( $fsz, 0, wxGROW );
    $topsz->Add( $ssz, 0, wxGROW );

    $self->SetSizerAndFit( $topsz );

    EVT_BUTTON( $self, $goto, sub { $self->GetParent->go_to( $self ) } );
    EVT_BUTTON( $self, $delete, sub { $self->GetParent->delete( $self ) } );
    EVT_TEXT( $self, $condition, sub { $self->GetParent->set_condition( $self, $condition->GetValue ) } );

    return $self;
}

sub display_bp {
    my( $self, $args ) = @_;

    my $text = basename( $args->{file} ) . ': ' . $args->{line};
    $self->controls->{label}->SetLabel( $text );
    $self->controls->{condition}->SetValue( $args->{condition} || '' );
}

1;
