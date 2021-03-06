#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = new Module::Build
    ( module_name => 'Wx::Spice',
      author      => 'Mattia Barbon <mbarbon@cpan.org>',
      license     => 'perl',
      requires    => { 'Wx'                    => 0.61,
                       'Wx::AUI'               => 0,
                       'Class::Accessor'       => 0.27,
                       'Module::Pluggable'     => 3.10,
                       'YAML'                  => 0.60,
                       'Config::IniFiles'      => 2.00,
                       'File::UserConfig'      => 0.04,
                       },
      build_requires => { 'Test::UseAllModules' => 0,
                          'Test::Differences'   => 0,
                          },
      create_makefile_pl => 'passthrough',
    );

$build->create_build_script;
