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
eval { use Test::Pod 1.00 };
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
