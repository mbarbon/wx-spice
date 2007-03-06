#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = new Module::Build
    ( module_name => 'Devel::ebug::Wx',
      author      => 'Mattia Barbon <mbarbon@cpan.org>',
      license     => 'perl',
      requires    => { 'Wx'                    => 0.61,
                       'Wx::AUI'               => 0,
                       'Wx::STC'               => 0,
                       'Class::Accessor'       => 0.27,
                       'Class::Publisher'      => 0.20,
                       'Devel::ebug'           => 0.46,
                       'Module::Pluggable'     => 3.10,
                       },
      create_makefile_pl => 'passthrough',
      no_index           => { package =>
                              [ 'Devel::ebug::Backend::Plugin::ActionPoints',
                                ],
                              },
    );

$build->create_build_script;
