#!/usr/bin/perl
#
# usage: perl fix_copyright.pl 0.02 lib/

use 5.014_001;
use warnings;
use Time::Piece;

my $NOW  = localtime(time);
my $YEAR = $NOW->year;

my $USAGE = "usage: $0 file ...\n";

if (!@ARGV || @ARGV < 2 || $ARGV[0] =~ /^-/) {
    die $USAGE;
}

local($^I) = '.bak';
local($/)  = undef;

while (<>) {
    # Fix version number.
    s(  ^
        (?<head>   \h* \# \h* )?
        (?<copyright> Copyright \h+ \([Cc]\) \h+ )
        (?<year>    \d+)
        (?<tail>    .*?)
        $
    )(
        $+{head}
        . new_copyright($+{copyright})
        . new_year($+{year})
        . $+{tail}
    )exm;
    print;
}

sub new_year {
    my ($old_year) = @_;

    return $old_year if $old_year eq $YEAR;
    my ($low, $high) = split qr{-}, $old_year, 2;
    return $old_year if $high && $high eq $YEAR;
    return "$low-$YEAR";
}

sub new_copyright {
    my ($text) = @_;

    $text =~ s/copyright/Copyright/gxsmi;
    $text =~ s/\( C \)/(c)/gxsm;
    return $text;
}
