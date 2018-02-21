#!/usr/bin/perl

use Modern::Perl;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Data::Dumper;

use Term::CLI;

$SIG{INT} = $SIG{QUIT} = 'IGNORE';

my @commands;
my $term = Term::CLI->new(
	name     => 'bssh',             # A basically simple shell.
	skip     => qr/^\s*(?:#.*)?$/,  # Skip comments and empty lines.
	prompt   => 'bssh> ',           # A more descriptive prompt.
);

push @commands, Term::CLI::Command::Help->new();

push @commands, Term::CLI::Command->new(
	name => 'exit',
    summary => 'exit the BSSH',
    description => "Exit the BSSH, with code I<excode>,\n"
                  ."or C<0> if no exit code is given.",
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

push @commands, Term::CLI::Command->new(
    name => 'ls',
    arguments => [
        Term::CLI::Argument::Filename->new( name => 'arg',
            min_occur => 0, max_occur => 0
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        my @args = @{$args{arguments}};
        do {
            system('ls', @args);
        };
        $args{status} = $?;
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'cp',
    arguments => [
        Term::CLI::Argument::Filename->new( name => 'path',
            min_occur => 2,
            max_occur => 0
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        my @src = @{$args{arguments}};
		my $dst = pop @src;
		
		say "command:     ".$cmd->name;
		say "source:      ".join(', ', @src);
		say "destination: ".$dst;

        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'sleep',
    arguments => [
        Term::CLI::Argument::Number::Int->new( name => 'time',
            min => 1, inclusive => 1
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;

        my $time = $args{arguments}->[0];

        say "-- sleep: $time";

        my %oldsig = %::SIG; # Save signals;

        # Make sure we can interrupt the sleep() call.
        $::SIG{INT} = $::SIG{QUIT} = sub {
            say STDERR "(interrupted by $_[0])";
        };

        my $slept = sleep($time);

        %::SIG = %oldsig; # Restore signal handlers.

        say "-- woke up after $slept sec", $slept == 1 ? '' : 's';
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'show',
    options => [ 'verbose|v' ],
    commands => [
        Term::CLI::Command->new( name => 'clock',
            options => [ 'timezone|tz|t=s' ],
            callback => \&do_show_clock,
        ),
        Term::CLI::Command->new( name => 'load',
            callback => \&do_show_uptime,
        ),
    ],
);

sub do_show_clock {
    my ($self, %args) = @_;
    return %args if $args{status} < 0;
    my $opt = $args{options};

    local($::ENV{TZ});
    if ($opt->{timezone}) {
        $::ENV{TZ} = $opt->{timezone};
    }
    say scalar(localtime);
    return %args;
}

sub do_show_uptime {
    my ($self, %args) = @_;
    return %args if $args{status} < 0;
    system('uptime');
    $args{status} = $?;
    return %args;
}

push @commands, Term::CLI::Command->new(
    name => 'debug',
    summary => 'debug individual commands',
    usage => 'B<debug> I<cmd> ...',
    commands => [@commands],
    callback => sub {
        my ($cmd, %args) = @_;
        my @args = @{$args{arguments}};
        say "# --- DEBUG ---";
        my $d = Data::Dumper->new([\%args], [qw(args)]);
        print $d->Maxdepth(2)->Indent(1)->Terse(1)->Dump;
        say "# --- DEBUG ---";
        return %args;
    }
);

$term->add_command(@commands);

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
