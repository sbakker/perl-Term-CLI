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

my $cli = Term::CLI->new(
    prompt => $FindBin::Script.'> ',
    commands => [
        $file_cmd, $sleep_cmd, $make_cmd,
    ],
    callback => sub {
        my $self = shift;
        my %args = @_;

        my $command_path = $args{command_path};
        say "path:", map { " ".$_->name } @$command_path;

        if ($args{status} < 0) {
            say "status: ".$args{status};
            say "error: <$args{error}>";
            $self->prompt("ERR[$args{status}]> ");
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

while (1) {
    my ($input, @input) = $cli->readline;
    last if !defined $input;

    next if $input =~ /^\s*(?:#.*)?$/;
    say "input:", map { " <$_>" } @input;
    $cli->execute(@input);
}
