#!/usr/bin/perl -T

use 5.014_001;
use strict;
use Modern::Perl;

sub Main {
    Term_CLI_test->SKIP_CLASS(
        ($::ENV{SKIP_COMMAND})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_test->runtests();
}

package Term_CLI_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI;
use Term::CLI::ReadLine;
use Term::CLI::Command;
use Term::CLI::Argument::Enum;
use Term::CLI::Argument::Filename;
use Term::CLI::Argument::Number::Int;

use File::Temp qw( tempdir );

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 2) {
    my $self = shift;

    my $copy_cmd = Term::CLI::Command->new(
        name => 'cp',
        options => ['interactive|i', 'force|f'],
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'src'),
            Term::CLI::Argument::Filename->new(name => 'dst'),
        ]
    );

    my $move_cmd = Term::CLI::Command->new(
        name => 'mv',
        options => ['interactive|i', 'force|f'],
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'src'),
            Term::CLI::Argument::Filename->new(name => 'dst'),
        ]
    );

    my $info_cmd = Term::CLI::Command->new(
        name => 'info',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'file')
        ]
    );

    my $file_cmd = Term::CLI::Command->new(
        name => 'file',
        options => ['verbose|v+', 'version|V', 'dry-run|D', 'debug|d+'],
        commands =>  [
            $copy_cmd, $move_cmd, $info_cmd
        ]
    );

    my $sleep_cmd = Term::CLI::Command->new(
        name => 'sleep',
        options => ['verbose|v+', 'debug|d+'],
        arguments => [
            Term::CLI::Argument::Number::Int->new(
                name => 'time', min => 1, inclusive => 1
            ),
        ]
    );

    my $make_cmd = Term::CLI::Command->new(
        name => 'make',
        options => ['verbose|v+', 'debug|d+'],
        arguments => [
            Term::CLI::Argument::Enum->new(
                name => 'thing', value_list => [qw( money love )]
            ),
            Term::CLI::Argument::Enum->new(
                name => 'when', value_list => [qw( always now later never )]
            ),
        ]
    );

    my $show_cmd = Term::CLI::Command->new(
        name => 'show',
        options => ['long|l', 'level|L', 'debug|d+', 'verbose|v+'],
        commands => [
            Term::CLI::Command->new(name => 'time'),
            Term::CLI::Command->new(name => 'date',
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'channel',
                        value_list => [qw( in out )]
                    ),
                ]
            ),
            Term::CLI::Command->new(name => 'debug',
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'channel',
                        value_list => [qw( in out )]
                    ),
                ]
            ),
            Term::CLI::Command->new(name => 'parameter',
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'param',
                        value_list => [qw( timeout maxlen prompt )]
                    ),
                    Term::CLI::Argument::Enum->new(name => 'channel',
                        value_list => [qw( in out )]
                    ),
                ]
            ),
        ]
    );
    isa_ok( $show_cmd, 'Term::CLI::Command',
            'Term::CLI::Command->new' );


    my $cli = Term::CLI->new(
        prompt => 'test> ',
        commands => [
            $file_cmd, $sleep_cmd, $make_cmd, $show_cmd,
        ]
    );
    isa_ok( $cli, 'Term::CLI', 'Term::CLI->new' );

    $self->{cli} = $cli;
}


sub check_command_names: Test(1) {
    my $self = shift;
    my $cli = $self->{cli};

    my @commands = sort { $a cmp $b } qw( file sleep make show );
    my @got = $cli->command_names();
    is_deeply(\@got, \@commands,
            'commands are (@commands)')
    or diag("command_names returned: (", join(", ", map {"'$_'"} @got), ")");
}


sub check_attributes: Test(1) {
    my $self = shift;
    my $cli = $self->{cli};
    is( $cli->prompt, 'test> ', "prompt attribute is 'test> '" );
}


sub check_complete_line: Test(4) {
    my $self = shift;
    my $cli = $self->{cli};

    my ($line, $text, $start, @got, @expected);

    $line = '';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = $cli->command_names();

    is_deeply(\@got, \@expected,
            'commands are (@expected)')
    or diag("complete_line('','',0) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'show ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( date debug parameter time );
    is_deeply(\@got, \@expected,
            'commands are (@expected)')
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'file --verbose cp ';
    $text = '--i';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( --interactive );
    is_deeply(\@got, \@expected,
            'completions are (@expected)')
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'file --verbose cp ';
    $text = '-i';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( -i );
    is_deeply(\@got, \@expected,
            'completions are (@expected)')
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");
}

}
Main();
