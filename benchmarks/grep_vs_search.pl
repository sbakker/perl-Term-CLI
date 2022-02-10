#!/usr/bin/perl

use 5.014;
use warnings;

use Benchmark qw( cmpthese );

my $iter = @ARGV ? shift @ARGV : 200_000;

my @list;

for my $c ('a' .. 'z') {
    my $prefix = $c x 4;

    push @list, $prefix;

    for my $i ( 1 .. 3 ) {
        push @list, $prefix . $i;
    }
}

sub grep_match {
    my ($text, $list) = @_;

    my @found = grep { rindex( $_, $text, 0 ) == 0 } @{$list};
    return @found;
}

sub search_match {
    my ($text, $list) = @_;
    my @found;
    foreach (@{$list}) {
        next if $_ lt $text;
        my $prefix = substr($_, 0, length($text));
        last if $prefix gt $text;
        push @found, $_ if $prefix eq $text;
    }
    return @found;
}

say "early match:";
cmpthese( $iter, {
    'grep' => sub { my @l = grep_match('aa', \@list) },
    'search' => sub { my @l = search_match('aa', \@list) },
    #'search2' => sub { my @l = search_match2('aa', \@list) },
} );

say "middle match:";
cmpthese( $iter, {
    'grep' => sub { my @l = grep_match('mm', \@list) },
    'search' => sub { my @l = search_match('mm', \@list) },
    #'search2' => sub { my @l = search_match2('mm', \@list) },
} );

say "late match:";
cmpthese( $iter, {
    'grep' => sub { my @l = grep_match('zz', \@list) },
    'search' => sub { my @l = search_match('zz', \@list) },
    #'search2' => sub { my @l = search_match2('zz', \@list) },
} );
