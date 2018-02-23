#!/usr/bin/perl -T

use 5.014_001;
use strict;
use Modern::Perl;

sub Main {
    Term_CLI_Command_Help_test->SKIP_CLASS(
        ($::ENV{SKIP_COMMAND})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Command_Help_test->runtests();
}

package Term_CLI_Command_Help_test {

use parent qw( Test::Class );

use Test::More;
use Test::Output;
use Test::Exception;
use FindBin;
use Term::CLI;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my @commands;

    push @commands,Term::CLI::Command->new(
        name => 'cp',
        summary => 'copy I<src> to I<dst>',
        options => ['interactive|i', 'force|f'],
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'src'),
            Term::CLI::Argument::Filename->new(name => 'dst'),
        ],
    );

    push @commands,Term::CLI::Command->new(
        name => 'mv',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'path', occur => 2),
        ],
    );

    push @commands,Term::CLI::Command::Help->new();

    my $cli = Term::CLI->new(
        prompt => 'test> ',
        callback => undef,
        commands => \@commands,
    );
    isa_ok( $cli, 'Term::CLI', 'Term::CLI->new' );

    $self->{cli} = $cli;
    $self->{commands} = [@commands];
}

sub check_help : Test(8) {
    my $self = shift;
    my $cli = $self->{cli};

    stdout_like(
        sub { $cli->execute('help') },
        qr/Commands:.*cp.*help.*mv/sm,
        'help returns command summary'
    );
    stdout_like(
        sub { $cli->execute('help --pod') },
        qr/=head2 Commands:.*B<cp>.*B<help>.*B<mv>/sm,
        'help --pod returns POD command summary'
    );

    stdout_like(
        sub { $cli->execute('help cp') },
        qr/Usage:.*cp.*--force.*src.*dst/sm,
        '"help cp" returns command help'
    );
    stdout_like(
        sub { $cli->execute('help --pod cp') },
        qr/=head2 Usage:.*B<cp>.*B<--force>.*I<src>.*I<dst>/sm,
        '"help --pod cp" returns POD command help'
    );

    my %args = $cli->execute('help xp');
    ok($args{status} < 0, '"help xp" results in an error"');
    like($args{error}, qr/unknown command/, 'error is set correctly');

    %args = $cli->execute('help cp sub');
    ok($args{status} < 0, '"help cp sub" results in an error"');
    like($args{error}, qr/cp: unknown command/, 'error is set correctly');
}

sub check_complete : Test(3) {
    my $self = shift;
    my $cli = $self->{cli};

    my (@got, @expected, $line, $text, $start);

    $line = 'help ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( cp help mv );
    is_deeply(\@got, \@expected,
            "completion for 'help': commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help ';
    $text = 'c';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( cp );
    is_deeply(\@got, \@expected,
            "completion for '$line$text': commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help cp ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw();
    is_deeply(\@got, \@expected,
            "completion for '$line$text': commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

}

}
Main();
