#!/usr/bin/perl
#
# Copyright (c) Steven Bakker
#
# See the "Copying" file that came with this package
# to see the licensing terms.
#

use 5.014_001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $module_name  = 'Term::CLI';
my $version_from = 'lib/Term/CLI/Version.pm';
my $changelog    = 'debian/changelog';
my $dfl_version  = '0.001';

## List of scripts in "bin" directory.
## Only if necessary...
# my @scripts = qw(
# );

WriteMakefile(
    find_version(),
    NAME          => $module_name,
    AUTHOR        => 'Steven Bakker <sb@monkey-mind.net>',
    ABSTRACT_FROM => 'lib/Term/CLI.pm',

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

sub find_version {
    my @version;

    if (-f $changelog) {
        # Read the package version from debian/changelog
        my ($module_version) = `head -1 $changelog 2>/dev/null`
            =~ m{
                \(
                (\d+ (?:\.\d+)) .*?
                \)
            }x;
        return (VERSION => $module_version) if $module_version;
    }

    return (VERSION_FROM => $version_from) if -f $version_from;
    return $dfl_version;
}
