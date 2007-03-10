package Devel::ebug::Wx::View::Expressions;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);

# expressions => ARRAY, _expressions ref to expressions
# FIXME: ought to be a service, too
__PACKAGE__->mk_accessors( qw(tree expressions) );

use Wx qw(:treectrl :sizer);
use Wx::Event qw(EVT_BUTTON EVT_TREE_ITEM_EXPANDING);

sub tag         { 'expressions' }
sub description { 'Expressions' }

sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    $self->expressions( [] );
    $self->{tree} = Wx::TreeCtrl->new( $self, -1, [-1,-1], [-1,-1],
                                       wxTR_HIDE_ROOT|wxTR_HAS_BUTTONS );

    my $refresh = Wx::Button->new( $self, -1, 'Refresh' );
    my $add = Wx::Button->new( $self, -1, 'Add' );
    my $expression = Wx::TextCtrl->new( $self, -1, '' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $cntrl = Wx::BoxSizer->new( wxHORIZONTAL );
    $cntrl->Add( $refresh, 0, 0 );
    $cntrl->Add( $add, 0, 0 );
    $cntrl->Add( $expression, 1, 0 );
    $sz->Add( $cntrl, 0, wxGROW );
    $sz->Add( $self->tree, 1, wxGROW );
    $self->SetSizer( $sz );

    $self->register_view;
    $self->tree->AddRoot( '' );

    EVT_TREE_ITEM_EXPANDING( $self, $self->tree, \&OnExpand );
    EVT_BUTTON( $self, $refresh, sub { $self->Refresh } );
    EVT_BUTTON( $self, $add, sub { 
                    $self->add_expression( $expression->GetValue );
                } );

    $self->SetSize( $self->default_size );

    return $self;
}

sub add_expression {
    my( $self, $expression ) = @_;

    push @{$self->expressions}, { expression => $expression,
                                  level      => 0,
                                  index      => @{$self->expressions},
                                  };
    $self->Refresh;
}

# FIXME global variable
# FIXME handle collapsing (reduce level il all siblings are collapsed)
our $processing;
sub OnExpand {
    my( $self, $event ) = @_;
    return if $processing;
    my( $item ) = $event->GetItem;
    my( $root, $expr_item, $level ) = ( $self->tree->GetRootItem, $item, 1 );
    while( $root != ( $item = $self->tree->GetItemParent( $item ) ) ) {
        ++$level;
        $expr_item = $item;
    }
    $self->tree->GetPlData( $expr_item )->{level} = $level;
    $self->Refresh;
}

sub Refresh {
    my( $self ) = @_;
    my $tree = $self->tree;

    my $root = $tree->GetRootItem;
    $tree->DeleteChildren( $root );
    foreach my $e ( @{$self->expressions} ) {
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
    local $processing = $processing + 1;
    my( $elts ) = $data->{keys};
    $self->tree->DeleteChildren( $item );
    foreach my $el ( @$elts ) {
        my $child = $self->tree->AppendItem( $item, $el->[0] . ' => ' . $el->[1]->{string} );
        $self->_add_childs( $child, $el->[1], $level ) if $el->[1]{keys};
    }
    $self->tree->Expand( $item ) if $processing <= $level;
}

1;
