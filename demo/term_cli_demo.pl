#!/usr/bin/perl

# See https://robots.thoughtbot.com/tab-completion-in-gnu-readline

use Modern::Perl;
use lib qw( ../lib );
use Data::Dumper;
use Term::CLI;
use Term::CLI::Command;
use Term::CLI::Argument::Filename;
use Term::CLI::Argument::Number::Int;
use Term::CLI::Argument::Enum;

my $copy_cmd = Term::CLI::Command->new(
    name => 'cp',
    options => ['verbose|v', 'debug|d', 'interactive|i', 'force|f'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ]
);

my $move_cmd = Term::CLI::Command->new(
    name => 'mv',
    options => ['verbose|v', 'debug|d', 'interactive|i', 'force|f'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ]
);

my $info_cmd = Term::CLI::Command->new(
    name => 'info',
    options => ['verbose|v', 'version|V', 'dry-run|D', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'file')
    ]
);

my $file_cmd = Term::CLI::Command->new(
    name => 'file',
    options => ['verbose|v', 'version|V', 'dry-run|D', 'debug|d'],
    commands =>  [
        $copy_cmd, $move_cmd, $info_cmd
    ]
);

my $sleep_cmd = Term::CLI::Command->new(
    name => 'sleep',
    options => ['verbose|v', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Number::Int->new(
            name => 'time', min => 1, inclusive => 1
        ),
    ]
);

my $make_cmd = Term::CLI::Command->new(
    name => 'make',
    options => ['verbose|v', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Enum->new(
            name => 'thing', value_list => [qw( money love )]
        ),
        Term::CLI::Argument::Enum->new(
            name => 'when', value_list => [qw( always now later never )]
        ),
    ]
);

my $cli = Term::CLI->new(
    prompt => $FindBin::Script.'> ',
    commands => [
        $file_cmd, $sleep_cmd, $make_cmd,
    ]
);

while (1) {
    my ($input, @input) = $cli->readline;
    last if !defined $input;

    next if $input =~ /^\s*(?:#.*)?$/;
    say "input:", map { " <$_>" } @input;
}
