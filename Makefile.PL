#!/usr/bin/perl
#
# Copyright (c) Steven Bakker - All rights reserved.
#
# See the "Copying" file that came with this package
# to see the licensing terms.
#

use 5.014_001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $module_name = 'Term::CLI';

# Read the package version from Changelog, assuming it
# is in Debian format.
my ($module_version) = `head -1 Changelog 2>/dev/null`
    =~ m{
        \(
        (\d+ (?:\.\d+)) .*?
        \)
    }x;

$module_version //= '0.01';

## List of scripts in "bin" directory.
## Only if necessary...
# my @scripts = qw(
# );

WriteMakefile(
    NAME         => $module_name,
    VERSION      => $module_version,
    AUTHOR       => 'First Last <First.Last@ams-ix.net>',

    PREREQ_FATAL => 0, # Change to 1 if you really need our prereqs.
    
    PREREQ_PM    => {
        # Include output from "perldepend --cpan bin/* lib/**/*.pm"
        'Carp'                => '1.40',
        'Data::Dumper'        => '2.160',
        'FindBin'             => '1.51',
        'Getopt::Long'        => '2.48',
        'List::Util'          => '1.4202',
        'Modern::Perl'        => '1.20170117',
        'Moo'                 => '2.002005',
        'Moo::Role'           => '2.002005',
        'POSIX'               => '1.65',
        'Term::ReadLine'      => '1.15',
        'Term::ReadLine::Gnu' => '1.35',
        'Text::ParseWords'    => '3.30',
        'Types::Standard'     => '1.000005',
        'namespace::clean'    => '0.27',
        'parent'              => '0.234',
    },

    BUILD_REQUIRES      => {
        # Include output from "perldepend --cpan t/*"
        'Test::Class'         => '0.50',
        'Test::Compile'       => 'v1.3.0',
        'Test::Exception'     => '0.43',
        'Test::More'          => '1.302103',
        'File::Temp'          => '0.2304',
    },
);
