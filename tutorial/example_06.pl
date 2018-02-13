#!/usr/bin/perl

use Modern::Perl;
use FindBin;
use lib ("$FindBin::Bin/../lib");

use Term::CLI;

$SIG{INT} = 'IGNORE';

my @commands;
my $term = Term::CLI->new(
	name     => 'bssh',             # A basically simple shell.
	skip     => qr/^\s*(?:#.*)?$/,  # Skip comments and empty lines.
	prompt   => 'bssh> ',           # A more descriptive prompt.
	commands => \@commands,
);

push @commands, Term::CLI::Command->new(
	name => 'exit',
	callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        execute_exit($cmd->name, @{$args{arguments}});
        return %args;
    },
	arguments => [
		Term::CLI::Argument::Number::Int->new(  # Integer
            name => 'excode',
			min => 0,             # non-negative
			inclusive => 1,       # "0" is allowed
			min_occur => 0,       # occurrence is optional
			max_occur => 1,       # no more than once
		),
	],
);

push @commands, Term::CLI::Command->new(
    name => 'echo',
    arguments => [
        Term::CLI::Argument::String->new( name => 'arg',
            min_occur => 0, max_occur => 0
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        say "@{$args{arguments}}";
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'make',
    arguments => [
        Term::CLI::Argument::Enum->new( name => 'target',
            value_list => [qw( love money)],
        ),
        Term::CLI::Argument::Enum->new( name => 'when',
            value_list => [qw( now later never forever )],
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        my @args = @{$args{arguments}};
        say "making $args[0] $args[1]";
        return %args;
    }
);


sub execute_exit {
    my ($cmd, $excode) = @_;
    $excode //= 0;
    say "-- $cmd: $excode";
    exit $excode;
}

say "\n[Welcome to BSSH]";
while ( defined(my $line = $term->readline) ) {
    $term->execute($line);
}
print "\n";
execute_exit('exit', 0);
