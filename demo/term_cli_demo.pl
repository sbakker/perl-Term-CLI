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
        Term::CLI::Argument::Number::Float->new(
            name => 'time', min => 0, inclusive => 0
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

my $set_cmd = Term::CLI::Command->new(
    name => 'set',
    commands => [
        Term::CLI::Command->new(
            name => 'delimiter',
            arguments => [
                Term::CLI::Argument::String->new(name => 'delimiter')
            ],
            callback => sub {
                my ($self, %args) = @_;
                my $args = $args{arguments};
                my $delimiters = $args->[0];
                my $path = $args{command_path};
                $path->[0]->word_delimiters($delimiters);
                return %args;
            }
        ),
        Term::CLI::Command->new(
            name => 'quote',
            arguments => [
                Term::CLI::Argument::String->new(name => 'quote')
            ],
            callback => sub {
                my ($self, %args) = @_;
                my $args = $args{arguments};
                my $quote_chars = $args->[0];
                my $path = $args{command_path};
                $path->[0]->quote_characters($quote_chars);
                return %args;
            }
        ),
    ]
);


my $cli = Term::CLI->new(
    prompt => $FindBin::Script.'> ',
    commands => [
        $file_cmd, $sleep_cmd, $make_cmd, $set_cmd,
    ],
    callback => sub {
        my $self = shift;
        my %args = @_;

        my $command_path = $args{command_path};
        say "path:", map { " ".$_->name } @$command_path;

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

        say "options: ";
        while (my ($k, $v) = each %{$args{options}}) {
            say "   --$k => $v";
        }
        say "arguments:", map {" '$_'"} @{$args{arguments}};
        return %args;
    }
);

while (my $input = $cli->readline(skip => qr/^\s*(?:#.*)?$/)) {
    $cli->execute($input);
}
