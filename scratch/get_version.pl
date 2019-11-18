#!/usr/bin/perl

use 5.014001;
use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../lib";

eval qq{use $ARGV[0]; print "\$$ARGV[0]\::VERSION\n"};
