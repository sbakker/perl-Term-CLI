#!/usr/bin/perl
#
# usage: perl fix_version_number.pl 0.02 lib/

use 5.014_001;
use Modern::Perl;

my $USAGE = "usage: $0 VERSION file ...\n";

if (!@ARGV || @ARGV < 2 || $ARGV[0] =~ /^-/) {
    die $USAGE;
}

our $VERSION = shift @ARGV;

local($^I) = '.bak';
local($/)  = undef;

while (<>) {
    # Fix version number.
    s/^(\s* package \s+ \S+) (?:\s* \S+)? \s* \{/$1  $VERSION {/xm;

    # Remove classic $VERSION assignment.
    s/^our \s+ \$VERSION \s* = \s* \S+ \s* ;\s*//xm;

    print;
}
