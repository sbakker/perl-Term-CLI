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

with('Term::CLI::Role::CommandSet');

has name => (
    is => 'ro',
    isa => Str,
    default => sub { $FindBin::Script }
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

    my $input = $self->term->readline($self->prompt);

    return if !defined $input;

    return ($input, shellwords($input));
}


sub execute {
    my ($self, @cmd) = @_;

    my %args = (
        command_path => [$self],
        arguments => \@cmd,
        error => '',
        options => {}
    );

    if (my $cmd = $self->find_command($cmd[0])) {
        %args = $cmd->execute(%args,
            arguments => [@cmd[1..$#cmd]]
        );
    }
    else {
        $args{error} = "unknown command '$cmd[0]'";
        $args{status} = -1;
    }

    return $self->try_callback(%args);
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI - CLI interpreter based on Term::ReadLine

=head1 SYNOPSIS

 use Term::CLI;
 use Term::CLI::Command;
 use Term::CLI::Argument::Filename;
 use Data::Dumper;

 my $cli = Term::CLI->new(
    name => 'myapp',
    prompt => 'myapp> ',
    callback => sub {
        my ($self, %args) = @_;
        print Data::Dumper->Dump([\%args], ['args']);
        return %args;
    }
    commands => [
        Term::CLI::Command->new(
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
        )
    ],
 );

 while (1) {
    my ($input, @input) = $cli->readline;
    last if !defined $input;
    next if $input =~ /^\s*(?:#.*)?$/;
    $cli->execute(@input);
 }

=head1 DESCRIPTION

Class for arguments in L<Term::CLI>(3p).
Inherits from the L<M6::CLI::Role::CommandSet>(3p)
role.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<attr> => I<VAL> ... )
X<new>

Create a new Term::CLI object and return a reference to it.

Valid attributes:

=over

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

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

=head1 INHERITED METHODS

This class inherits all the attributes and accessors of
L<Term::CLI::Role::CommandSet>(3p), most notably:

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

=head1 METHODS

=over

=item B<name>
X<name>

Return the application name.

=item B<prompt> ( [ I<Str> ] )
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

=item B<find_command> ( I<Str> )
X<find_command>

Check whether I<Str> is a command in this C<Term::CLI> object.
If so, return the appropriate L<Term::CLI::Command> object;
otherwise, return C<undef>.

=item B<option_names>
X<option_names>

Return a list of all command line options for this command.
Long options are prefixed with C<-->, and one-letter options
are prefixed with C<->.

=item B<readline>
X<readline>

Read a line from the input connected to L<term|/term>, using
the L<Term::ReadLine> interface.

Returns a list of strings. The first element is the literal
line read from the input (minus any line terminator). The
other elements are the elements after splitting the line
into words. The splitting is done with L<Text::ParseWords>'s
L<shellwords()|Text::ParseWords/shellwords>.

Returns an empty value if end of file has been reached (e.g.
the user hitting I<Ctrl-D>).

Example:

    my ($line, @line) = $cli->readline;

    exit if !defined $line;

=item B<execute> ( I<Str>, ... )
X<execute>

Parse and execute the command line consisting of I<Str>s
(see the return value of L<readline|/readline> above).

Example:

    while (1) {
        my ($line, @line) = $cli->readline;

        exit if !defined $line;

        $cli->execute(@line);
    }

The command line is parsed depth-first, and for every
L<Term::CLI::Command>(3p) encountered, that object's
callback function is executed.

=over

=item *

Suppose that the C<file> command has a C<show> sub-command that takes
an optional C<--verbose> option and a single file argument.

=item *

Suppose the input is:

    file show --verbose foo.txt

=item *

Then the parse tree looks like this:

    (cli-root)
        |
        +--> Command 'file'
                |
                +--> Command 'show'
                        |
                        +--> Option '--verbose'
                        |
                        +--> Argument 'foo.txt'

=item *

Then the callbacks will be called in the following order:

=over

=item 1.

Callback for 'show'

=item 2.

Callback for 'file'

=item 3.

Callback for C<Term::CLI> object.

=back

The return value from each callback (a hash in list form) is fed into the
next callback function in the chain. This allows for adding custom data to
the return hash that will be fed back up the parse tree (and eventually to
the caller).

=back

=back

=head1 SEE ALSO

L<FindBin>(3p),
L<Getopt::Long>(3p),
L<Term::CLI>(3p),
L<Term::CLI::Argument>(3p),
L<Term::CLI::Command>(3p),
L<Term::CLI::Role::CommandSet>(3p),
L<Text::ParseWords>(3p),
L<Types::Standard>(3p).

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
