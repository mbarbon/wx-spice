package Devel::ebug::Wx::View::Expressions;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);

# FIXME: ought to be a service, too
__PACKAGE__->mk_accessors( qw(tree _expressions) );

use Wx qw(:treectrl :textctrl :sizer WXK_DELETE);
use Wx::Event qw(EVT_BUTTON EVT_TREE_ITEM_EXPANDING EVT_TEXT_ENTER
                 EVT_TREE_BEGIN_LABEL_EDIT EVT_TREE_END_LABEL_EDIT
                 EVT_TREE_KEY_DOWN);

sub tag         { 'expressions' }
sub description { 'Expressions' }

sub expressions { @{$_[0]->_expressions} }

# FIXME backport to wxPerl
sub _call_on_idle($&) {
    my( $window, $code ) = @_;

    use Wx::Event qw(EVT_IDLE);
    # Disconnecting like this is unsafe...
    my $callback = sub {
        EVT_IDLE( $window, undef );
        $code->();
    };
    EVT_IDLE( $window, $callback );
}

sub new {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    $self->_expressions( [] );
    $self->{tree} = Wx::TreeCtrl->new( $self, -1, [-1,-1], [-1,-1],
                                       wxTR_HIDE_ROOT | wxTR_HAS_BUTTONS |
                                       wxTR_EDIT_LABELS );

    my $refresh = Wx::Button->new( $self, -1, 'Refresh' );
    my $add = Wx::Button->new( $self, -1, 'Add' );
    my $expression = Wx::TextCtrl->new( $self, -1, '', [-1, -1], [-1, -1],
                                        wxTE_PROCESS_ENTER );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $cntrl = Wx::BoxSizer->new( wxHORIZONTAL );
    $cntrl->Add( $refresh, 0, 0 );
    $cntrl->Add( $add, 0, 0 );
    $cntrl->Add( $expression, 1, 0 );
    $sz->Add( $cntrl, 0, wxGROW );
    $sz->Add( $self->tree, 1, wxGROW );
    $self->SetSizer( $sz );

    $self->subscribe_ebug( 'state_changed', sub { $self->_refresh( @_ ) } );
    $self->set_layout_state( $layout_state ) if $layout_state;
    $self->register_view;
    $self->tree->AddRoot( '' );

    EVT_TREE_ITEM_EXPANDING( $self, $self->tree, \&_on_expand );
    EVT_BUTTON( $self, $refresh, sub { $self->refresh } );
    EVT_BUTTON( $self, $add, sub {
                    $self->add_expression( $expression->GetValue );
                } );
    EVT_TEXT_ENTER( $self, $expression,
                    sub { $self->add_expression( $expression->GetValue ) } );
    EVT_TREE_BEGIN_LABEL_EDIT( $self, $self->tree, \&_begin_edit );
    EVT_TREE_END_LABEL_EDIT( $self, $self->tree, \&_end_edit );
    EVT_TREE_KEY_DOWN( $self, $self->tree, \&_key_down );

    $self->SetSize( $self->default_size );

    return $self;
}

sub add_expression {
    my( $self, $expression ) = @_;

    push @{$self->_expressions}, { expression => $expression,
                                   level      => 0,
                                   };
    $self->refresh;
}

sub _is_expression {
    return $_[0]->GetItemParent( $_[1] ) == $_[0]->GetRootItem;
}

sub _key_down {
    my( $self, $event ) = @_;

    return unless $event->GetKeyCode == WXK_DELETE;
    my $item = $event->GetItem || $self->tree->GetSelection;
    return unless _is_expression( $self->tree, $item );
    my $expression = $self->tree->GetPlData( $item );
    $self->_expressions( [ grep $_ ne $expression, $self->expressions ] );
    _call_on_idle $self, sub { $self->refresh };
}

# only allow editing root items
sub _begin_edit {
    my( $self, $event ) = @_;
    my $tree = $self->tree;

    if( !_is_expression( $tree, $event->GetItem ) ) {
        $event->Veto;
    } else {
        my $expr = $tree->GetPlData( $event->GetItem )->{expression};
        $tree->SetItemText( $event->GetItem, $expr );
    }
}

sub _end_edit {
    my( $self, $event ) = @_;

    $self->tree->GetPlData( $event->GetItem )->{expression} = $event->GetLabel;
    _call_on_idle $self, sub { $self->refresh };
}

sub _on_expand {
    my( $self, $event ) = @_;
    return if $self->{_expanding}; # avoid processing while in refresh

    my( $item ) = $event->GetItem;
    my( $root, $expr_item, $level ) = ( $self->tree->GetRootItem, $item, 1 );
    while( $root != ( $item = $self->tree->GetItemParent( $item ) ) ) {
        ++$level;
        $expr_item = $item;
    }
    $self->tree->GetPlData( $expr_item )->{level} = $level;
    $self->refresh;
}

sub _refresh {
    my( $self, $ebug, $event, %params ) = @_;

    $self->refresh;
}

sub refresh {
    my( $self ) = @_;
    my $tree = $self->tree;

    my $root = $tree->GetRootItem;
    $tree->DeleteChildren( $root );
    foreach my $e ( $self->expressions ) {
        my $child = $tree->AppendItem( $root, $e->{expression}, -1, -1,
                                       Wx::TreeItemData->new( $e ) );
        my( $val, $ex ) = $self->ebug->eval_level( $e->{expression},
                                                   $e->{level} );
        if( $ex ) {
            chomp $val;
            $tree->SetItemText( $child, "$e->{expression} = $val"  );
        } else {
            $tree->SetItemText( $child, "$e->{expression} = $val->{string}"  );
            $self->_add_childs( $child, $val, $e->{level} ) if $val->{keys}
        }
    }
}

sub _add_childs {
    my( $self, $item, $data, $level ) = @_;
    local $self->{_expanding} = $self->{_expanding} + 1;
    my( $elts ) = $data->{keys};
    $self->tree->DeleteChildren( $item );
    foreach my $el ( @$elts ) {
        my $child = $self->tree->AppendItem( $item, $el->[0] . ' => ' . $el->[1]->{string} );
        $self->_add_childs( $child, $el->[1], $level ) if $el->[1]{keys};
    }
    $self->tree->Expand( $item ) if $self->{_expanding} <= $level;
}

1;
