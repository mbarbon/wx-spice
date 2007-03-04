package Devel::ebug::Wx::Command::Views;

use Module::Pluggable
      sub_name    => 'views',
      search_path => 'Devel::ebug::Wx::View',
      require     => 1,
      except      => qr/::Base$|::View::Code::/;

sub register_commands {
    my( $class ) = @_;
    my @commands;

    foreach my $view ( $class->views ) {
        my $cmd = sub {
            my( $wx ) = @_;

            my $instance = $view->new( $wx, $wx );
            $wx->manager->AddPane
              ( $instance, $wx->pane_info->Name( $view->tag )->Float
                ->Caption( $view->description ) );
            $wx->manager->Update;
        };
        push @commands, 'show_' . $view->tag,
             { sub      => $cmd,
               menu     => 'view',
               label    => sprintf( "Show %s", $view->description ),
               priority => 200,
               };
    }

    return @commands;
}

1;
