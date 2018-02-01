#===============================================================================
#
#       Module:  Term::CLI
#
#  Description:  Class for CLI parsing
#
#       Author:  Steven Bakker (SB), <Steven.Bakker@ams-ix.net>
#      Created:  31/01/18
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

package Term::CLI {

our $VERSION = '1.00';

use Modern::Perl;
use List::Util qw( first );
use Text::ParseWords qw( shellwords );
use Carp qw( croak );
use Term::CLI::ReadLine;
use FindBin;

use Types::Standard qw(
    ArrayRef
    CodeRef
    InstanceOf
    Maybe
    Str
);

use Moo;
use namespace::clean;

has name => (
    is => 'ro',
    isa => Str,
    default => sub { $FindBin::Script }
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

has prompt => (
    is => 'rw',
    isa => Str,
    default => sub { '~> ' }
);

sub term { return Term::CLI::ReadLine->term }

# BOOL = CLI->_is_escaped($line, $index);
#
# The character at $index in $line is a possible word break
# character. Check if it is perhaps escaped.
#
sub _is_escaped {
    my ($self,$line, $index) = @_;
    return (
        $index > 0 &&
        substr($line, $index-1, 1) eq '\\' &&
        !$self->_is_escaped($line, $index-1)
    );
}

sub BUILD {
    my ($self, $args) = @_;

    my $term = Term::CLI::ReadLine->new($self->name)->term;
    $term->Attribs->{completion_function} = sub { $self->complete_line(@_) };
    $term->Attribs->{completer_quote_characters} = q{"'};

    # Default: \n\t\\ "'`@$><=;|&{(
    $term->Attribs->{completer_word_break_characters} = "\t\n ";
    $term->Attribs->{char_is_quoted_p} = sub { $self->_is_escaped(@_) };
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
    my ($self, $text, $line, $start) = @_;

    my $attribs = $self->term->Attribs;

    my $quote_char = $attribs->{completion_quote_character} =~ s/\000//gr;
    my @words;

    if ($start > 0) {
        if (length $quote_char) {
            # ReadLine thinks the $text to be completed is quoted.
            # The quote character will precede the $start of $text.
            # Make sure we do not include it in the text to break
            # into words...
            @words = shellwords(substr($line, 0, $start-1));
        }
        else {
            @words = shellwords(substr($line, 0, $start));
        }
    }
    push @words, $text;

    #say STDERR "complete_line: text=<$text>; line=<$line>; start=<$start>";
    #say STDERR "complete_line: words: ", map {" <$_>"} @words;

    my @list;
    if ($self->has_commands) {
        if (@words == 1) {
            @list = $self->command_names;
        }
        elsif (my $cmd = $self->find_command($words[0])) {
            @list = $cmd->complete_line(@words[1..$#words]);
        }
    }

    #$self->term->forced_update_display;

    # Escape spaces in reply if necessary.
	if (length $quote_char) {
        return @list;
    }
    else {
        return map { s/(\s)/\\$1/gr } @list;
    }
}

sub readline {
    my $self = shift @_;

    my $input = $self->term->readline($self->prompt) or return;

    return ($input, shellwords($input));
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

=item B<new> ( B<attr> => I<VAL> ... )
X<new>

Create a new Term::CLI object and return a reference to it.

Valid attributes:

=over

=item B<callback> =E<gt> I<CODEREF>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

Mutually exclusive with B<arguments>.

=item B<commands> =E<gt> I<ARRAYREF>

Reference to an array containing L<Term::CLI::Command> object
instances that describe the commands that C<Term::CLI> recognises,
or C<undef>.

=item B<name> =E<gt> I<STRING>

The application name. This is used for e.g. the history file
and default command prompt.

If not given, defaults to C<$FindBin::Script> (see L<FindBin>(3p)).

=item B<prompt> =E<gt> I<STRING>

Prompt to display when L<readline|/readline> is called. Defaults
to the application name with C<E<gt>> and a space appended.

=back

=back

=head1 ACCESSORS

This class inherits all the attributes of L<Term::CLI::Element>(3p).
In addition, it adds the following:

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

   CLI_REF->callback->(CLI_REF,
        args => HASHREF,
        opts => HASHREF,
        cmd_line => ARRAYREF,
        cmd_index => INTEGER
   );

Where:

=over

=item I<CLI_REF>

Reference to the current C<Term::CLI> object.

=item C<args>

Reference to a hash containing all the (named) arguments.
Each value is the L<value|Term::CLI::Argument/value> of
a L<Term::CLI::Argument> object.

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

=item B<commands> ( [ I<ARRAYREF> ] )
X<commands>

I<ARRAYREF> with L<Term::CLI::Command> object instances.

=item B<name>
X<name>

Return the application name.

=item B<prompt> ( [ I<STRING> ] )
X<prompt>

Get or set the command line prompt to display to the user.

=item B<term>
X<term>

Return a reference to the underlying L<Term::CLI::ReadLine> object.

=back

=head1 METHODS

=over

=item B<complete_line> ( I<TEXT>, I<LINE>, I<START> )
X<complete_line>

Called when the user hits the I<TAB> key for completion.

I<TEXT> is the text to complete, I<LINE> is the input line so
far, I<START> is the position in the line where I<TEXT> starts.

The function will split the line in words and delegate the
completion to the first L<Term::CLI::Command> sub-command,
see L<Term::CLI::Command|Term::CLI::Command/complete_line>.

=item B<command_names>
X<command_names>

Return a list of command names, sorted alphabetically.

=item B<find_command> ( I<CMD> )
X<find_command>

Check whether I<CMD> is a command in this C<Term::CLI> object.
If so, return the appropriate L<Term::CLI::Command> object;
otherwise, return C<undef>.

=item B<option_names>
X<option_names>

Return a list of all command line options for this command.
Long options are prefixed with C<-->, and one-letter options
are prefixed with C<->.

=item B<readline>
X<readline>

Read a line 

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::CLI::Element>(3p),
L<Term::CLI>(3p),
L<Text::ParseWords>(3p),
L<FindBin>(3p),
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
