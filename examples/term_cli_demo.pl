#!/usr/bin/perl

# See https://robots.thoughtbot.com/tab-completion-in-gnu-readline

use Modern::Perl;
use lib qw( ../lib );
use Data::Dumper;
use Term::CLI;
use Term::CLI::Command;
use Term::CLI::Argument::Filename;
use Term::CLI::Argument::Number::Float;
use Term::CLI::Argument::Enum;
use Term::CLI::Argument::String;

my $test_1_cmd = Term::CLI::Command->new(
    name => 'test_1',
    arguments => [
        Term::CLI::Argument::Enum->new(name => 'arg',
            value_list => [qw( one two three )],
            min_occur => 0,
            max_occur => 2
        ),
    ]
);

my $test_2_cmd = Term::CLI::Command->new(
    name => 'test_2',
    arguments => [
        Term::CLI::Argument::Enum->new(name => 'arg',
            value_list => [qw( one two three four )],
            min_occur => 1,
            max_occur => 0
        ),
    ],
    description => "Test the 'one or more' arguments construct",
);

my $copy_cmd = Term::CLI::Command->new(
    name => 'cp',
    options => ['verbose|v', 'debug|d', 'interactive|i', 'force|f'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
    description => "Copy file <src> to <dst>",
);

my $move_cmd = Term::CLI::Command->new(
    name => 'mv',
    options => ['verbose|v', 'debug|d', 'interactive|i', 'force|f'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
    description => "Move file/directory <src> to <dst>",
);

my $info_cmd = Term::CLI::Command->new(
    name => 'info',
    options => ['verbose|v', 'version|V', 'dry-run|D', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'file')
    ],
    description => "Show information about <file>",
);

my $file_cmd = Term::CLI::Command->new(
    name => 'file',
    options => ['verbose|v', 'version|V', 'dry-run|D', 'debug|d'],
    commands =>  [
        $copy_cmd, $move_cmd, $info_cmd
    ],
    description => "Various file operations.",
);

my $sleep_cmd = Term::CLI::Command->new(
    name => 'sleep',
    options => ['verbose|v', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Number::Float->new(
            name => 'time', min => 0, inclusive => 0
        ),
    ],
    description => "Sleep for <time> seconds.",
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
    ],
    description => "Make <thing> at time <when>.",
);

my $set_cmd = Term::CLI::Command->new(
    name => 'set',
    commands => [
        Term::CLI::Command->new(
            name => 'delimiter',
            description => 'Set the word delimiter',
            arguments => [
                Term::CLI::Argument::String->new(name => 'delimiter')
            ],
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                my $args = $args{arguments};
                my $delimiters = $args->[0];
                my $path = $args{command_path};
                $path->[0]->word_delimiters($delimiters);
                return %args;
            }
        ),
        Term::CLI::Command->new(
            name => 'quote',
            description => 'Set the quote character for strings',
            arguments => [
                Term::CLI::Argument::String->new(name => 'quote')
            ],
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                my $args = $args{arguments};
                my $quote_chars = $args->[0];
                my $path = $args{command_path};
                $path->[0]->quote_characters($quote_chars);
                return %args;
            }
        ),
    ],
    description => 'Set CLI parameters'
);


my @commands = (
    $file_cmd, $sleep_cmd, $make_cmd, $set_cmd,
    $test_1_cmd, $test_2_cmd,
    Term::CLI::Command::Help->new(),
);

my $cli = Term::CLI->new(
    prompt => $FindBin::Script.'> ',
    commands => \@commands,
    callback => sub {
        my $self = shift;
        my %args = @_;

        my $command_path = $args{command_path};
        #say "path:", map { " ".$_->name } @$command_path;

        if ($args{status} < 0) {
            say "** ERROR: $args{error}";
            say "(status: $args{status})";
            $self->prompt("ERR[$args{status}]> ");
            return %args;
        }
        elsif ($args{status} == 0) {
            $self->prompt('OK> ');
        }
        else {
            $self->prompt("ERR[$args{status}]> ");
        }

        #say "options: ";
        #while (my ($k, $v) = each %{$args{options}}) {
            #say "   --$k => $v";
        ##}
        #say "arguments:", map {" '$_'"} @{$args{arguments}};
        return %args;
    }
);

#say "TEST: " . $cli->_commands . " <=> " . \@commands;
#
#for my $cmd ($cli->commands) {
#    say $cmd->name." parent ".$cmd->parent->name;
#}

while (my $input = $cli->readline(skip => qr/^\s*(?:#.*)?$/)) {
    $cli->execute($input);
}
