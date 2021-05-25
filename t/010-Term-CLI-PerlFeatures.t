#!perl
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014;
use warnings;

use Test::More 1.001002;
use Test::Compile v1.2.0;

BEGIN { use_ok('Term::CLI::PerlFeatures') }

eval { Term::CLI::PerlFeatures->unimport };

is($@, '', 'unimport (no) Term::CLI::PerlFeatures');

done_testing();
