package Wx::Spice;

use strict;

our $VERSION = '0.10';

=head1 NAME

Wx::Spice - the Spice GUI application framework 

=head1 SYNOPSIS

  use Wx::Spice::ServiceManager;
  # load service-defining modules, via use(), Module::Pluggable, ...

  # at startup
  my $sm = Wx::Spice::ServiceManager->new;
  $sm->initialize;
  $sm->load_configuration;

  # main processing here

  # before exiting
  $sm->finalize;

=head1 DESCRIPTION

=head1 SEE ALSO

L<Wx::Spice::ServiceManager>, L<Wx>, L<Devel::ebug::Wx>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
