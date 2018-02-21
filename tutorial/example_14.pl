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
	name => 'quit',
    summary => 'exit the BSSH with code 0',
	callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        execute_exit($cmd->name, 0);
        return %args;
    },
);

push @commands, Term::CLI::Command->new(
    name => 'inform',
    summary => 'inform I<dst_ip> about I<src_ip>',
    arguments => [
        Term::CLI::Argument::String->new( name => 'dst_ip' )
    ],
    commands => [
        Term::CLI::Command->new(
            name => 'about',
            summary => 'inform I<dst_ip> about I<src_ip>',
            arguments => [
                Term::CLI::Argument::String->new( name => 'src_ip' )
            ],
            callback => sub {
                my ($cmd, %args) = @_;
                return %args if $args{status} < 0;

                my ($dst_ip, $src_ip) = @{$args{arguments}};

                say "-- inform: $dst_ip about $src_ip";
                return %args;
            },
        ),
    ],
);

push @commands, Term::CLI::Command->new(
    name => 'time',
    arguments => [
        Term::CLI::Argument::Number::Int->new( name => 'time',
            min => 1, inclusive => 1
        ),
    ],
    commands => [
        Term::CLI::Command->new(
            name => 'sleep',
            summary => 'sleep for I<time> seconds',
            description => 'Sleep for I<time> seconds.'
                        .  'This action can be interrupted by'
                        .  ' an INT (I<Ctrl-C> or QUIT (I<Ctrl-\>) signal.',
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
            },
        ),
        Term::CLI::Command->new(
            name => 'say',
            summary => 'tell the time I<time> seconds from now',
            description => 'Display the time I<time> seconds from now.',
            options => [ 'timezone|tz|t=s' ],
            callback => sub {
                my ($cmd, %args) = @_;
                return %args if $args{status} < 0;
                my $opt = $args{options};

                my $time = $args{arguments}->[0];

                local($::ENV{TZ});
                if ($opt->{timezone}) {
                    $::ENV{TZ} = $opt->{timezone};
                }

                my $t = time + $time;
                say scalar(localtime($t));
                return %args;
            },
        ),
    ],
);


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
