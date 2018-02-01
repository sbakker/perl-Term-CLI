#===============================================================================
#
#       Module:  Term::CLI::Command
#
#  Description:  Class for (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SB), <Steven.Bakker@ams-ix.net>
#      Created:  30/01/18
#
#   Copyright (c) 2018 Steven Bakker; All rights reserved.
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#===============================================================================

use 5.014_001;

package Term::CLI::Command {

our $VERSION = '1.00';

use Modern::Perl;
use List::Util qw( first );
use Carp qw( croak );
use Getopt::Long qw( GetOptionsFromArray );
use Data::Dumper;

use Types::Standard qw(
    ArrayRef 
    CodeRef
    InstanceOf
    Maybe 
    Str
);

use Moo;
use namespace::clean;

extends 'Term::CLI::Element';

has options => (
    is => 'rw',
    isa => Maybe[ArrayRef[Str]],
    predicate => 1
);

has arguments => (
    is => 'rw',
    isa => Maybe[ArrayRef[InstanceOf['Term::CLI::Argument']]],
    predicate => 1
);

has commands => (
    is => 'rw',
    isa => Maybe[ArrayRef[InstanceOf['Term::CLI::Command']]],
    predicate => 1
);

has callback => (
    is => 'rw',
    isa => Maybe[CodeRef],
    predicate => 1
);

before arguments => sub {
    my $self = shift;
    if (@_ && $_[0]) {
        croak "arguments and commands are mutually exclusive"
            if $self->has_commands;
    }
};

before 'commands' => sub {
    my $self = shift;
    if (@_ && $_[0]) {
        croak "arguments and commands are mutually exclusive"
            if $self->has_arguments;
    }
};

sub option_names {
    my $self = shift;
    my $opt_specs = $self->options or return ();
    my @names;
    for my $spec (@$opt_specs) {
        for my $optname (split(qr/\|/, $spec =~ s/^([^!+=:]+).*/$1/r)) {
            push @names, length($optname) == 1 ? "-$optname" : "--$optname";
        }
    }
    return @names;
}

sub command_names {
    my $self = shift;
    return if !$self->has_commands;
    return sort { $a cmp $b } map { $_->name } @{$self->commands};
}

sub find_command {
    my ($self, $command_name) = @_;
    return undef if !$self->has_commands;
    return first { $_->name eq $command_name } @{$self->commands};
}

sub complete_line {
    my ($self, @words) = @_;

    my $partial = $words[$#words];

    if ($self->has_options) {

        Getopt::Long::Configure(qw(bundling require_order pass_through));
        my $opt_specs = $self->options;
        my %parsed_opts;
        eval { GetOptionsFromArray(\@words, \%parsed_opts, @$opt_specs) };

        if (@words && $words[0] eq '--') {
            shift @words;
        }
        if (@words == 0 && $partial =~ /^-/) {
            # We have to complete a command-line option.
            return grep { rindex($_, $partial, 0) == 0 } $self->option_names;
        }
    }
    
    if ($self->has_commands) {
        if (@words <= 1) {
            return $self->command_names;
        }
        elsif (my $cmd = $self->find_command($words[0])) {
            return $cmd->complete_line(@words[1..$#words]);
        }
    }
    elsif ($self->has_arguments) {
        my @args = @{$self->arguments};
        while (@words > 1) {
            shift @args;
            shift @words;
            last if @args == 0;
        }

        return @args ? $args[0]->complete($words[0]) : ();
    }
    return ();
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Command - Class for (sub-)commands in Term::CLI

=head1 SYNOPSIS

 use Term::CLI::Command;
 use Term::CLI::Argument::Filename;
 use Data::Dumper;

 my $arg = Term::CLI::Command->new(
    name => 'command',
    options => [ 'verbose!' ],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
    callback => sub {
        my ($self, $args, $opts) = @_;
        print Data::Dumper->Dump([$args, $opts], [qw(args opts)]);
    }
 );

=head1 DESCRIPTION

Class for arguments in L<Term::CLI>(3p).
Inherits from L<M6::CLI::Element>(3p).

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new Term::CLI::Argument object and return a reference to it.

The B<name> attribute is required.

Other attributes are:

=over

=item B<options> =E<gt> I<ARRAYREF>

Reference to an array containing command options in
L<Getopt::Long>(3p) style, or C<undef>.

=item B<arguments> =E<gt> I<ARRAYREF>

Reference to an array containing L<Term::CLI::Argument>(3p) object
instances that describe the parameters that the command takes,
or C<undef>.

Mutually exclusive with B<commands>.

=item B<commands> =E<gt> I<ARRAYREF>

Reference to an array containing C<Term::CLI::Command> object
instances that describe the sub-commands that the command takes,
or C<undef>.

Mutually exclusive with B<arguments>.

=item B<callback> =E<gt> I<CODEREF>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

Mutually exclusive with B<arguments>.

=back

=back

=head1 ACCESSORS

This class inherits all the attributes and accessors of
L<Term::CLI::Element>(3p). In addition, it adds the following:

=over

=item B<has_arguments>
X<has_arguments>

=item B<has_callback>
X<has_callback>

=item B<has_commands>
X<has_commands>

=item B<has_options>
X<has_options>

Predicate functions that return whether or not the associated
attribute has been set.

=item B<options> ( [ I<ARRAYREF> ] )
X<options>

I<ARRAYREF> with command-line options in L<Getopt::Long>(3p) format.

=item B<arguments> ( [ I<ARRAYREF> ] )
X<arguments>

I<ARRAYREF> with L<Term::CLI::Argument>(3p) object instances.

=item B<commands> ( [ I<ARRAYREF> ] )
X<commands>

I<ARRAYREF> with C<Term::CLI::Command> object instances.

=item B<callback> ( [ I<CODEREF> ] )
X<callback>

I<CODEREF> to be called when the command is executed. The code
is called as:

   COMMAND_REF->callback->(COMMAND_REF,
        args => ARRAYREF,
        opts => HASHREF,
        cmd_line => ARRAYREF,
        cmd_index => INTEGER
   );

Where:

=over

=item I<COMMAND_REF>

Reference to the current C<Term::CLI::Command> object.

=item C<args>

Reference to an array containing all the non-option arguments.

=item C<opts>

Reference to a hash containing all command line options.
Compatible with the options hash as set by L<Getopt::Long>(3p).

=item C<cmd_line>

Reference to an array containing the command line, split into
words. The splitting is done with L<Text::ParseWords>'s
L<shellwords()|Text::ParseWords/shellwords>.

=item C<cmd_index>

Non-negative integer indicating where in C<cmd_line> the
current command was found.

=back

=back

=head1 METHODS

=over

=item B<complete_line> ( I<WORD>, ... )
X<complete_line>

The I<WORD> arguments make up the parameters to this command.
Given those, this method attempts to generate possible completions
for the last I<WORD> in the list.

The method can complete options, sub-commands, and arguments.
Completions of commands and arguments is delegated to the appropriate
L<Term::CLI::Command> and L<Term::CLI::Argument> instances, resp.

=item B<command_names>
X<command_names>

Return the list of (sub-)command names, sorted alphabetically.

=item B<find_command> ( I<CMD> )
X<find_command>

Check whether I<CMD> is a sub-command of this command. If so,
return the appropriate C<Term::CLI::Command> reference; otherwise,
return C<undef>.

=item B<option_names>
X<option_names>

Return a list of all command line options for this command.
Long options are prefixed with C<-->, and one-letter options
are prefixed with C<->.

Example:

    $cmd->options( [ 'verbose|v+', 'debug|d', 'help|h|?' ] );
    say join(' ', $cmd->option_names);
    # output: --debug --help --verbose -? -d -h -v

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::CLI::Element>(3p),
L<Term::CLI>(3p),
L<Text::ParseWords>(3p),
L<Getopt::Long>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sb@monkey-mind.netE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker; All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
