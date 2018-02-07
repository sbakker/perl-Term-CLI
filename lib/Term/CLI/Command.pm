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
use List::Util qw( first min );
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

with ('Term::CLI::Role::CommandSet');

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

sub BUILD {
    my ($self, $args) = @_;
    croak "arguments and commands are mutually exclusive"
        if $self->has_arguments and $self->has_commands;
}

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

sub argument_names {
    my $self = shift;
    return if !$self->has_arguments;
    return map { $_->name } @{$self->arguments};
}

sub complete_line {
    my ($self, @words) = @_;

    my $partial = $words[$#words] // '';

    if ($self->has_options) {

        Getopt::Long::Configure(qw(bundling require_order pass_through));

        my $opt_specs = $self->options;

        my %parsed_opts;

        my $has_terminator = first { $_ eq '--' } @words[0..$#words-1];

        eval { GetOptionsFromArray(\@words, \%parsed_opts, @$opt_specs) };

        if (!$has_terminator && @words <= 1 && $partial =~ /^-/) {
            # We have to complete a command-line option.
            return grep { rindex($_, $partial, 0) == 0 } $self->option_names;
        }
    }

    if ($self->has_commands) {
        if (@words <= 1) {
            return grep { rindex($_, $partial, 0) == 0 } $self->command_names;
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


sub execute {
    my ($self, %args) = @_;

    my $options = $args{options};
    my @command_path = (@{$args{command_path}}, $self);

    push @{$args{command_path}}, $self;

    if ($self->has_options) {
        my $opt_specs = $self->options;

        Getopt::Long::Configure(qw(bundling require_order no_pass_through));

        my $error = '';
        my $ok = do {
            local( $SIG{__WARN__} ) = sub { chomp($error = join('', @_)) };
            GetOptionsFromArray($args{arguments}, $args{options}, @$opt_specs);
        };

        if (!$ok) {
            return $self->try_callback(
                %args,
                status => -1,
                error => $error,
            );
        }
    }

    if ($self->has_commands) {
        return $self->try_callback( $self->_execute_command(%args) );
    }
    else {
        return $self->try_callback( $self->_check_arguments(%args) );
    }
}


sub _check_arguments {
    my ($self, %args) = @_;

    my @arguments = @{$args{arguments}};

    my @arg_spec = $self->has_arguments ? @{$self->arguments} : ();

    if (@arg_spec == 0 && @arguments > 0) {
        return (%args, status => -1, error => 'no arguments allowed');
    }

    my $argno = 0;
    my @parsed_args;
    for my $arg_spec (@arg_spec) {
        if (@arguments < $arg_spec->min_occur) {
            my $error = "arg#".($argno+1).": need ";
            if ($arg_spec->max_occur == $arg_spec->min_occur) {
                $error .= $arg_spec->min_occur . ' '
                        . $arg_spec->name . ' argument';
                $error .= 's' if $arg_spec->max_occur > 1;
            }
            elsif ($arg_spec->max_occur > 1) {
                $error .= 'between ' . $arg_spec->min_occur
                        . ' and ' . $arg_spec->max_occur
                        . ' ' . $arg_spec->name . ' arguments';
            }
            else {
                $error .= 'at least ' . $arg_spec->min_occur
                        . ' ' . $arg_spec->name . ' argument';
                $error .= 's' if $arg_spec->min_occur > 1;
            }
            return (%args, status => -1, error => $error);
        }

        my $args_to_check
            = $arg_spec->max_occur > 0
                ? min($arg_spec->max_occur, scalar @arguments)
                : scalar @arguments;

        my @args_to_check = splice @arguments, 0, $args_to_check;
        for my $arg (@args_to_check) {
            $argno++;
            my $arg_value = $arg_spec->validate($arg);
            if (!defined $arg_value) {
                return (%args, status => -1,
                    error => "arg#$argno, '$arg': " . $arg_spec->error
                             . " for " . $arg_spec->name
                );
            }
            push @parsed_args, $arg_value;
        }
    }

    # At this point, we have processed all our arg_spec.  The only way there
    # are any elements left in @arguments is for the last arg_spec to have
    # a limited number of allowed values.
    if (@arguments) {
        my $last_spec = $arg_spec[$#arg_spec];
        return (%args, status => -1,
            error => "arg#$argno, ".$last_spec->name.": too many arguments"
        );
    }
    return (%args, status => 0, error => '', arguments => \@parsed_args);
}


sub _execute_command {
    my ($self, %args) = @_;

    my @arguments = @{$args{arguments}};

    if (! @arguments) {
        return (%args, status => -1, error => "missing sub-command");
    }

    my $cmd_name = shift @arguments;

    my $cmd = $self->find_command($cmd_name);

    if (!$cmd) {
        return (%args, status => -1, error => "unknown sub-command '$cmd_name'");
    }

    return $cmd->execute(
        command_path => $args{command_path},
        arguments => \@arguments,
        options => $args{options},
    );
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

 my $copy_cmd = Term::CLI::Command->new(
    name => 'copy',
    options => [ 'verbose!' ],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
    callback => sub {
        my ($self, %args) = @_;
        print Data::Dumper->Dump([\%args], ['args']);
        return (%args, status => 0);
    }
 );

=head1 DESCRIPTION

Class for arguments in L<Term::CLI>(3p).
Inherits from L<M6::CLI::Element>(3p) and
L<M6::CLI::Role::CommandSet>(3p).

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new Term::CLI::Command object and return a reference to it.

The B<name> attribute is required.

Other attributes are:

=over

=item B<arguments> =E<gt> I<ArrayRef>

Reference to an array containing L<Term::CLI::Argument>(3p) object
instances that describe the parameters that the command takes,
or C<undef>.

Mutually exclusive with B<commands>.

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=item B<commands> =E<gt> I<ArrayRef>

Reference to an array containing C<Term::CLI::Command> object
instances that describe the sub-commands that the command takes,
or C<undef>.

Mutually exclusive with B<arguments>.

=item B<options> =E<gt> I<ArrayRef>

Reference to an array containing command options in
L<Getopt::Long>(3p) style, or C<undef>.

=back

=back

=head1 INHERITED METHODS

This class inherits all the attributes and accessors of
L<Term::CLI::Element>(3p) and L<Term::CLI::Role::CommandSet>(3p), most notably:

=head2 Accessors

=over

=item B<has_callback>
X<has_callback>

See
L<has_callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_callback>.

=item B<has_commands>
X<has_commands>

See
L<has_commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_commands>.

=item B<commands> ( [ I<ArrayRef> ] )
X<commands>

See
L<commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/commands>.

I<ArrayRef> with C<Term::CLI::Command> object instances.

=item B<callback> ( [ I<CodeRef> ] )
X<callback>

See
L<callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/callback>.

=back

=head2 Other

=over

=item B<command_names>
X<command_names>

Return the list of (sub-)command names, sorted alphabetically.

=item B<find_command> ( I<CMD> )
X<find_command>

Check whether I<CMD> is a sub-command of this command. If so,
return the appropriate C<Term::CLI::Command> reference; otherwise,
return C<undef>.

=back

=head1 METHODS

=head2 Accessors

=over

=item B<has_arguments>
X<has_arguments>

=item B<has_options>
X<has_options>

Predicate functions that return whether or not the associated
attribute has been set.

=item B<options> ( [ I<ArrayRef> ] )
X<options>

I<ArrayRef> with command-line options in L<Getopt::Long>(3p) format.

=item B<arguments> ( [ I<ArrayRef> ] )
X<arguments>

I<ArrayRef> with L<Term::CLI::Argument>(3p) object instances.

=back

=head2 Others

=over

=item B<complete_line> ( I<WORD>, ... )
X<complete_line>

The I<WORD> arguments make up the parameters to this command.
Given those, this method attempts to generate possible completions
for the last I<WORD> in the list.

The method can complete options, sub-commands, and arguments.
Completions of commands and arguments is delegated to the appropriate
L<Term::CLI::Command> and L<Term::CLI::Argument> instances, resp.

=item B<argument_names>
X<argument_names>

Return the list of argument names, in the original order.

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
L<Term::CLI::Role::CommandSet>(3p),
L<Term::CLI>(3p),
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

=begin __PODCOVERAGE

=head1 THIS SECTION SHOULD BE HIDDEN

This section is meant for methods that should not be considered
for coverage. This typically includes things like BUILD and DEMOLISH from
Moo/Moose. It is possible to skip these when using the Pod::Coverage class
(using C<also_private>), but this is not an option when running C<cover>
from the command line.

The simplest trick is to add a hidden section with an item list containing
these methods.

=over

=item BUILD

=item DEMOLISH

=back

=end __PODCOVERAGE

=cut
