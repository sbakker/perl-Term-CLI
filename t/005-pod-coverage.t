#!/usr/bin/perl -T
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use strict;
use Test::More;
eval { use Test::Pod::Coverage 1.04 };
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
}

if (exists $::ENV{'POD_COVERAGE'} && $::ENV{'POD_COVERAGE'} =~ /^(y|yes|true|0*[1-9])/) {
    all_pod_coverage_ok(
        { also_private => [ qr/BUILD/, qr/DEMOLISH/ ] }
    );
}
else {
    Test::More::plan(
        skip_all => "Set POD_COVERAGE=1 to run"
    );
}
