#!/usr/bin/perl
#
# usage: perl fix_version_number.pl 0.02 lib/

use 5.014_001;
use warnings;

my $USAGE = "usage: $0 VERSION file ...\n";

if (!@ARGV || @ARGV < 2 || $ARGV[0] =~ /^-/) {
    die $USAGE;
}

our $VERSION = shift @ARGV;

my $auto_increment = 0;

if ($VERSION eq '+1') {
    $auto_increment = 1;
}
elsif ($VERSION !~ /^\d+(?:\.\d+)?/) {
    die "$0: bad version format '$VERSION'\n";
}

local($^I) = '.bak';
local($/)  = undef;

while (<>) {
    # Fix version number.
    s(  ^
        (?<head>   \s* package \s+ \S+)
        (?<version> (?:\s* \S+)?)
        (?<tail>    \s* [\{\;])
    )(
        $+{head} . "  " . new_version($+{version}) . $+{tail}
    )exm;

    # Update classic $VERSION assignment.
    s(  ^
        (?<head>    \s* our \s+ \$VERSION \s* = \s* )
        (?<version> \S+)
        (?<tail>    \s* ;\s*)
    )(
        $+{head} . new_version($+{version}) . $+{tail}
    )exm;

    print;
}

sub new_version {
    my ($cur) = @_;

    return $VERSION if !$auto_increment;
    return '0.01' if !$cur;
    my $add = $cur =~ s/0+$//gr;
    $add =~ s/\d/0/g;
    $add =~ s/\d$/1/;
    return $cur + $add;
}
