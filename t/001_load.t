#!/usr/bin/perl -w

use strict;
use Test::UseAllModules;

BEGIN {
    require Wx;
    require Wx::Spice::ServiceManager;
    all_uses_ok except => 'Wx::Spice::ServiceManager';
}

exit 0;
