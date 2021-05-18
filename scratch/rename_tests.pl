#!/usr/bin/env perl
use 5.014;
use warnings;

my @files = qw(
00-compile.t
01-pod-coverage.t
02-pod.t
05-Term-CLI-Element.t
10-Term-CLI-Argument.t
11-Term-CLI-Argument-Enum.t
12-Term-CLI-Argument-Filename.t
13-Term-CLI-Argument-Number.t
14-Term-CLI-Argument-Number-Int.t
15-Term-CLI-Argument-Number-Float.t
16-Term-CLI-Command.t
17-Term-CLI.t
18-Term-CLI-ReadLine.t
);

my $n = 0;
for my $f (@files) {
    my $f2 = $f;
    $f2 =~ s/^\d+-/sprintf("%03d-", $n)/e;
    $n += 5;
    say "git mv $f $f2";
}
