#===============================================================================
#
#       Module:  Term::CLI::CommandSet
#
#  Description:  Class for sets of (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SB), <Steven.Bakker@ams-ix.net>
#      Created:  05/02/18
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

package Term::CLI::Role::CommandSet {

use Modern::Perl;
use Term::CLI::Version qw( $VERSION );
use List::Util qw( first min );
use Carp qw( croak );
use Getopt::Long qw( GetOptionsFromArray );
use Data::Dumper;

use Types::Standard qw(
    ArrayRef
    CodeRef
    InstanceOf
    Maybe
);

use Moo::Role;
use namespace::clean;

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

sub command_names {
    my $self = shift;
    return if !$self->has_commands;
    return sort { $a cmp $b } map { $_->name } @{$self->commands};
}

sub find_command {
    my ($self, $partial) = @_;
    return undef if !$self->has_commands;
    my @found = grep { rindex($_->name, $partial, 0) == 0 } @{$self->commands};
    return @found == 1 ? $found[0] : undef;
}

sub try_callback {
    my ($self, %args) = @_;

    if ($self->has_callback) {
        return $self->callback->($self, %args);
    }
    else {
        return %args;
    }
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Role::CommandSet - Role for (sub-)commands in Term::CLI

=head1 SYNOPSIS

 package Term::CLI::Command {

    use Moo;

    with('Term::CLI::Role::CommandSet');

    ...
 };

 my $cmd = Term::CLI::Command->new( ... );

 $cmd->callback->( %args ) if $cmd->has_callback;

 if ( $cmd->has_commands ) {
    die "$cmd_name not found" unless $cmd->find_command( $cmd_name );
 }

 say "command names:", join(', ', $cmd->command_names);

 $cmd->callback->( $cmd, %args ) if $cmd->has_callback;

 %args = $cmd->try_callback( %args );

=head1 DESCRIPTION

Role for L<Term::CLI>(3p) elements that contain
a set of L<Term::CLI::Command>(3p) objects.

This role is used by L<Term::CLI>(3p) and L<Term::CLI::Command>(3p).

=head1 ATTRIBUTES

This role defines two additional attributes:

=over

=item B<commands> =E<gt> I<ArrayRef>

Reference to an array containing C<Term::CLI::Command> object
instances that describe the sub-commands that the command takes,
or C<undef>.

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=back

=head1 ACCESSORS AND PREDICATES

=over

=item B<has_callback>
X<has_callback>

=item B<has_commands>
X<has_commands>

Predicate functions that return whether or not the associated
attribute has been set.

=item B<callback> ( [ I<CODEREF> ] )
X<callback>

I<CODEREF> to be called when the command is executed. The callback
is called as:

   OBJ->callback->(OBJ,
        status       => Int,
        error        => Str,
        options      => HashRef,
        arguments    => ArrayRef[Value],
        command_line => Str,
        command_path => ArrayRef[InstanceOf['Term::CLI::Command']],
   );

Where:

=over

=item I<CLI_REF>

Reference to the current C<Term::CLI> object.

=item C<status>

Indicates the status of parsing/execution so far.
It has the following meanings:

=over

=item I<E<lt> 0>

Negative status values indicate a parse error. This is a sign that no
action should be taken, but some error handling should be performed.
The actual parse error can be found under the C<error> key. A typical
thing to do in this case is for one of the callbacks in the chain (e.g.
the one on the C<Term::CLI> object to print the error to F<STDERR>).

=item I<0>

The command line parses as valid and execution so far has been successful.

=item I<E<gt> 0>

Some error occurred in the execution of the action. Callback functions need
to set this by themselves.

=back

=item C<error>

In case of a negative C<status>, this will contain the parse error. In
all other cases, it may or may not contain useful information.

=item C<options>

Reference to a hash containing all command line options.
Compatible with the options hash as set by L<Getopt::Long>(3p).

=item C<arguments>

Reference to an array containing all the arguments to the command.
Each value is a scalar value, possibly converted by
its corresponding L<Term::CLI::Argument>'s
L<validate|Term::CLI::Argument/validate> method (e.g. C<3e-1> may have
been converted to C<0.3>).

=item C<command_line>

The complete command line as given to the
L<Term::CLI::execute|Term::CLI/execute> method.  

=item C<command_path>

Reference to an array containing the "parse tree", i.e. a list
of object references:

    [
        InstanceOf['Term::CLI'],
        InstanceOf['Term::CLI::Command'],
        ...
    ]

The first item in the C<command_path> list is always the top-level
L<Term::CLI> object, while the last is always the same as the
I<OBJ_REF> parameter.

=back

The callback is expected to return a hash (list) containing at least the
same keys. The C<command_path>, C<arguments>, and C<options> should
be considered read-only.

Note that a callback can be called even in the case of errors, so you
should always check the C<status> before doing anything.

=item B<commands> ( [ I<ArrayRef> ] )
X<commands>

Get or set the I<ArrayRef> with C<Term::CLI::Command>
object instances.

=back

=head1 METHODS

=over

=item B<command_names>
X<command_names>

Return the list of (sub-)command names, sorted alphabetically.

=item B<find_command> ( I<Str> )
X<find_command>

Check whether I<Str> is a command in this C<Term::CLI> object.
If so, return the appropriate L<Term::CLI::Command> object;
otherwise, return C<undef>.

=item B<try_callback> ( I<ARGS> )
X<try_callback>

Wrapper function that will call the object's C<callback> function if it
has been set, otherwise simply returns its arguments.

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Command>(3p).

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
