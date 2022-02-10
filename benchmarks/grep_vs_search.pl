#!/usr/bin/perl
#
# Benchmark showing that finding prefix matches in
# a *sorted* list of strings is faster using a loop
# with shortcutting than a `grep` with `rindex`.
#

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

sub grep_rindex {
    my ($text, $list) = @_;

    my @found = grep { rindex( $_, $text, 0 ) == 0 } @{$list};
    return @found;
}

sub grep_substr {
    my ($text, $list) = @_;

    my @found = grep { substr( $_, 0, length $text ) eq $text } @{$list};
    return @found;
}


sub search_rindex {
    my ($text, $list) = @_;

    my @found;
    foreach (@{$list}) {
        next if $_ lt $text;
        if (rindex( $_, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last if substr($_, 0, length $text) gt $text;
    }
    return @found;
}

sub search_substr {
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
    'grep_rindex'   => sub { my @l = grep_rindex('aa', \@list) },
    'grep_substr'   => sub { my @l = grep_substr('aa', \@list) },
    'search_substr' => sub { my @l = search_substr('aa', \@list) },
    'search_rindex' => sub { my @l = search_rindex('aa', \@list) },
} );

say "\nmiddle match:";
cmpthese( $iter, {
    'grep_rindex'   => sub { my @l = grep_rindex('mmm', \@list) },
    'grep_substr'   => sub { my @l = grep_substr('mmm', \@list) },
    'search_substr' => sub { my @l = search_substr('mmm', \@list) },
    'search_rindex' => sub { my @l = search_rindex('mmm', \@list) },
} );

say "\nlate match:";
cmpthese( $iter, {
    'grep_rindex' => sub { my @l = grep_rindex('zzzz', \@list) },
    'grep_substr' => sub { my @l = grep_substr('zzzz', \@list) },
    'search_substr' => sub { my @l = search_substr('zzzz', \@list) },
    'search_rindex' => sub { my @l = search_rindex('zzzz', \@list) },
} );
