#=============================================================================
#
#       Module:  Term::CLI::ReadLine
#
#  Description:  Class for Term::CLI and Term::ReadLine glue
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  23/Jan/2018
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::ReadLine  0.052005 {

use 5.014;
use strict;
use warnings;

use Carp qw( confess );

use parent 0.228 qw( Term::ReadLine );

use Term::ReadKey ();

use namespace::clean 0.25;

my $DFL_HIST_SIZE = 500;
my $Term = undef;

my $History_Size = $DFL_HIST_SIZE;
my @History      = ();

sub new {
    my $class = shift;

    return $Term if $Term;

    $Term = Term::ReadLine->new(@_);
    my $rl = $Term->ReadLine;
    $Term->Attribs->{catch_signals} = 1;
    bless $Term, $class;
    return $Term->_install_stubs;
}

sub term { return $Term }

sub term_width {
    my $self = shift;
    my ($rows, $cols) = $self->get_screen_size();
    return $cols;
}

sub term_height {
    my $self = shift;
    my ($rows, $cols) = $self->get_screen_size();
    return $rows;
}

sub echo_signal_char {
    my ($self, $sig_arg) = @_;

    state %name2int = (
        'INT' => 2,
        'QUIT' => 3,
        'TSTP' => 20
    );

    state %sigchar = (
        2 => '^C',
        3 => '^\\',
        20 => '^Z',
    );

    if ($sig_arg =~ /\D/) {
        $sig_arg = $name2int{uc $sig_arg} or return;
    }

    if ($self->ReadLine =~ /::Gnu$/) {
        return $self->SUPER::echo_signal_char($sig_arg);
    }

    my $char = $sigchar{$sig_arg} or return;
    $self->OUT->print($char);
    return;
}

sub _escape_str {
    my ($self, $str) = @_;
    $str =~ s/\t/\\t/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/([\177-\377])/sprintf("\\%03o", ord($1))/ge;
    $str =~ s/([\000-\037])/'^'.chr(ord($1)+ord('@'))/ge;
    return $str;
}

# The GNU readline implementation will just slap the prompt between the
# ornament-start/ornament-end sequences, but this looks ugly if there
# are leading/trailing spaces and the ornament is set to underline
# (or standout). The following will bring it in line with how the Perl
# implementation handles it, by inserting start/end sequences where
# necessary.
sub _prepare_prompt {
    my ($self, $prompt) = @_;

    return $prompt if $self->ReadLine !~ /::Gnu$/;
    return $prompt if length $self->Attribs->{term_set}[0] == 0;

    my ($head, $body, $tail) = $prompt =~ /^(\s*)(.*?)(\s*)$/;
    return $prompt if ($head eq '' and $tail eq '');

    #say "prompt:       ", $self->_escape_str("<$head><$body><$tail>");
    #say "start_ignore: ", $self->_escape_str($self->RL_PROMPT_START_IGNORE);
    #say "end_ignore:   ", $self->_escape_str($self->RL_PROMPT_END_IGNORE);
    #say "term_set 0:   ", $self->_escape_str($self->Attribs->{term_set}[0]);
    #say "term_set 1:   ", $self->_escape_str($self->Attribs->{term_set}[1]);

    $prompt = '';
    if (length $head) {
        $prompt .= $self->Attribs->{term_set}[1]
                . $head
                . $self->Attribs->{term_set}[0]
                ;
    }
    #say $self->_escape_str($prompt);

    $prompt .= $body;
    #say $self->_escape_str($prompt);
    
    if (length $tail) {
        $prompt .= $self->Attribs->{term_set}[1]
                . $tail
                ;
    }
    #say $self->_escape_str($prompt);

    return $prompt;
}

sub readline {
    my ($self, $prompt) = @_;

    my %old_sig = $self->_set_signal_handlers;

    $prompt = $self->_prepare_prompt($prompt);

    my $input = $self->SUPER::readline($prompt);

    %SIG = %old_sig; # Restore signal handlers.

    if (!$self->Features->{autohistory}) {
        if (defined $input && length($input)) {
            $self->AddHistory($input);
        }
    }
    return $input;
}

# %old_sig = CLI->_set_signal_handlers();
#
# Set signal handlers to ensure proper terminal/CLI handling in the
# face of various signals (^C ^\ ^Z).
#
sub _set_signal_handlers {
    my $self = shift;

    my %old_sig = %SIG;

    my $last_sig = '';

    # The generic signal handler will attempt to re-throw the signal, after
    # putting the terminal in the correct state. Any previously set signal
    # handlers should then be triggered.
    my $generic_handler = sub {
        my ($signal) = @_;

        my $this_handler = $SIG{$signal};
        my $handler = $old_sig{$signal} // '';

        $self->deprep_terminal();
        if (ref $handler) {
            local($SIG{$signal}) = $handler;
            $handler->($signal, @_);
        }
        elsif ($handler eq '' or $handler eq 'DEFAULT') {
            local($SIG{$signal}) = $handler;
            kill $signal, $$;
        }
        $self->prep_terminal(1);
        $self->forced_update_display();
        return 1;
    };

    if ($self->ReadLine =~ /::Gnu$/) {
        for my $sig (qw( HUP QUIT ALRM TERM )) {
            $SIG{$sig} = $generic_handler if ref $old_sig{$sig};
        }
    }
    else {
        $SIG{HUP} = $SIG{QUIT} = $SIG{ALRM} = $SIG{TERM} = $generic_handler;
    }

    # The INT signal handler; slightly different from
    # the generic one: we abort the current input line.
    $SIG{INT} = sub {
        my ($signal) = @_;
        if ($self->ReadLine =~ /::Gnu$/) {
            $self->crlf;
        }
        $self->replace_line('');
        $generic_handler->($signal);
        return 1;
    };

    # The CONT signal handler.
    # In case we get suspended, make sure we redraw the CLI on wake-up.
    $SIG{CONT} = sub {
        my ($signal) = @_;
        $last_sig = $signal;
        $old_sig{$signal}->(@_) if ref $old_sig{$signal};
        return 1;
    };     

    $self->Attribs->{signal_event_hook} = sub {
        if ($last_sig eq 'CONT') {
            $self->forced_update_display();
        }
        return 1;
    };

    return %old_sig;
}


# Install stubs for common GRL methods.
sub _install_stubs {
    my ($self) = @_;

    return $self if $self->ReadLine =~ /::Gnu$/;

    no warnings 'once';

    *{free_line_state} = sub { };
    *{crlf}            = sub { $self->OUT->print("\n") };

    *{get_screen_size} = sub {
        my ($width, $height) = Term::ReadKey::GetTerminalSize($_[0]->OUT);
        return ($height, $width);
    };

    if ($self->ReadLine !~ /::Perl$/) {
        *{replace_line} = 
        *{prep_terminal} =
        *{deprep_terminal} =
        *{forced_update_display} = sub { };

        return $self;
    }

    *{replace_line} = \&_perl_replace_line;
    *{prep_terminal} = \&_perl_prep_terminal;
    *{deprep_terminal} = \&_perl_deprep_terminal;
    *{forced_update_display} = \&_perl_forced_update_display;

    return $self;
}

# Term::ReadLine::Perl implementations of GRL methods.
sub _perl_prep_terminal         { readline::SetTTY() }
sub _perl_deprep_terminal       { readline::ResetTTY() }
sub _perl_forced_update_display { readline::redisplay() }

sub _perl_replace_line {
    my ($self, $line) = @_;
    $line //= '';
    $readline::line = $line;
    $readline::D = length($line) if $readline::D > length($line);
    return;
}

sub ReadHistory {
    my ($self, $hist_file) = @_;

    if ($self->Features->{'readHistory'}) {
        return $self->SUPER::ReadHistory($hist_file);
    }

    open my $fh, '<', $hist_file or return;

    my @history;
    while (<$fh>) {
        next if /^$/;
        chomp;
        shift @history if @history == $History_Size;
        push @history, $_;
    }
    $fh->close;

    $self->term->SetHistory(@history);
    return 1;
}

sub WriteHistory {
    my ($self, $hist_file) = @_;

    if ($self->Features->{'writeHistory'}) {
        return $self->SUPER::WriteHistory($hist_file);
    }

    open my $fh, '>', $hist_file or return;
    print $fh map { "$_\n" } $self->term->GetHistory or return;
    $fh->close or return;
    return 1;
}

*{stifle_history} = \&StifleHistory;
sub StifleHistory {
    my ($self, $max) = @_;

    if ($self->Features->{'stiflehistory'}) {
        return $self->SUPER::StifleHistory($max);
    }

    $max //= 1e12;
    $max = 0 if $max <= 0;

    if ($self->ReadLine =~ /::Perl$/) {
        $readline::rl_MaxHistorySize = $max;
        my $cur = int @readline::rl_History;
        if ($cur > $max) {
            splice(@readline::rl_History, 0, -$max);
            $readline::rl_HistoryIndex -= ($cur - $max);
        }
        return $max;
    }

    splice(@History, 0, -$max) if @History > $max;
    $History_Size = $max;
    return $max;
}

sub GetHistory {
    my ($self) = @_;

    if ($self->Features->{'getHistory'}) {
        return $self->SUPER::GetHistory();
    }
    return @History;
}

sub SetHistory {
    my ($self, @l) = @_;

    splice(@l, 0, -$History_Size) if @l > $History_Size;

    if ($self->Features->{'setHistory'}) {
        return $self->SUPER::SetHistory(@l);
    }

    @History = @l;

    return int(@History);
}

sub AddHistory {
    my ($self, @lines) = @_;

    if ($self->Features->{'addHistory'}) {
        return $self->SUPER::AddHistory(@lines);
    }

    push @History, @lines;
    splice(@History, 0, -$History_Size) if int(@History) > $History_Size;
    return;
}

}
1;

__END__

=pod

=head1 NAME

Term::CLI::ReadLine - Term::ReadLine compatibility layer for Term::CLI

=head1 SYNOPSIS

 use Term::CLI::ReadLine;

 sub initialise {
    my $term = Term::CLI::ReadLine->new( ... );
    ... # Use Term::ReadLine methods on $term.
 }

 # The original $term reference is now out of scope, but
 # we can get a reference to it again:

 sub somewhere_else {
    my $term = Term::CLI::ReadLine->term;
    ... # Use Term::ReadLine methods on $term.
 }

=head1 DESCRIPTION

This class provides a compatibility layer between L<Term::ReadLine>(3p)
and L<Term::CLI>(3p). If L<Term::ReadLine::Gnu>(3p) is not loaded as the
C<Term::ReadLine> implementation, this class will compensate for the lack
of certain functions by replacing or wrapping methods that are needed
by the rest of the L<Term::CLI>(3p) classes.

The ultimate purpose is to behave as consistently as possible regardless
of the C<Term::ReadLine> interface that has been loaded.

This class inherits from L<Term::ReadLine> and keeps a single instance
around with a class accessor to access that single instance, because
even though L<Term::ReadLine>(3p) has an object-oriented interface,
the L<Term::ReadLine::Gnu>(3p) and L<Term::ReadLine::Perl>(3p) modules
really only keeps a single instance around (if you create multiple
L<Term::ReadLine> objects, all parameters and history are shared).

=head1 CONSTRUCTORS

=over

=item B<new> ( ... )
X<new>

Create a new L<Term::CLI::ReadLine>(3p) object and return a reference to it.

Arguments are identical to L<Term::ReadLine>(3p).

A reference to the newly created object is stored internally and can be
retrieved later with the L<term|/term> class method. Note that repeated calls
to C<new> will reset this internal reference.

=back

=head1 METHODS

See L<Term::ReadLine>(3p), L<Term::ReadLine::Gnu>(3p) and/or
L<Term::ReadLine::Perl> for the inherited methods.

=over

=item B<echo_signal_char> ( I<signal> )
X<echo_signal_char>

Print the character that generates a particular signal when entered from
the keyboard (e.g. C<^C> for keyboard interrupt).

This method also accepts a signal name instead of a signal number. It only
works for C<INT> (2), C<QUIT> (3), and C<TSTP> (20) signals as these are
the only ones that can be entered from a keyboard.

If L<Term::ReadLine::Gnu> is loaded, this method wraps around the method of
the same name in C<Term::ReadLine::Gnu> (translating a signal name to a
number first). For other C<Term::ReadLine> implementations, it emulates the
C<Term::ReadLine::Gnu> behaviour.

=item B<readline> ( I<prompt> )
X<readline>

Wrap around the original L<Term::ReadLine's readline|Term::ReadLine/readline>
with custom signal handling, see the
L<CAVEATS section in Term::CLI|Term::CLI/CAVEATS>.

This also calls C<AddHistory> if C<autohistory> is not set in C<Features>.

=item B<term_width>
X<term_width>

Return the width of the terminal in characters, as given by
L<Term::ReadLine>.

=item B<term_height>
X<term_height>

Return the height of the terminal in characters, as given by
L<Term::ReadLine>.

=item B<AddHistory> ( I<line>, ... )
X<AddHistory>

=item B<GetHistory>
X<GetHistory>

=item B<ReadHistory> ( I<file> )
X<ReadHistory>

=item B<SetHistory> ( I<line>, ... )
X<SetHistory>

=item B<StifleHistory> ( I<max_lines> )
X<StifleHistory>

=item B<stifle_history> ( I<max_lines> )
X<stifle_history>

=item B<WriteHistory> ( I<file> )
X<WriteHistory>

Depending on the underlying C<Term::ReadLine> implementation, these will
either call the parent class's method, or implement a proper emulation.

In the case of C<Term::ReadLine::Perl>, this means that C<ReadHistory>
and C<WriteHistory> implement their own file I/O read/write (because
C<Term::ReadLine::Perl> doesn't provide them); furthermore, C<StifleHistory>
uses knowledge of C<Term::ReadLine::Perl>'s internals to manipulate the
history.

In cases where history is not supported at all (e.g. C<Term::ReadLine::Stub>,
the history list is kept in this object and manipulated.

=back

=head1 STUB METHODS

If C<Term::ReadLine> is I<not> using the GNU ReadLine library, this object
provides stubs for a few GNU ReadLine methods:

=over

=item B<free_line_state>
X<free_line_state>

=item B<forced_update_display>
X<forced_update_display>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to force an redraw of the input line.

=item B<crlf>
X<crlf>

Prints a newline to the terminal's output.

=item B<replace_line> ( I<str> )
X<replace_line>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to replace the current input line with I<str>.

=item B<deprep_terminal>
X<deprep_terminal>

=item B<prep_terminal>
X<prep_terminal>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to either restore (deprep) terminal settings to
what they were before calling C<readline>, or to set them to what
C<readline> uses. You will rarely (if ever) need these, since
the ReadLine libraries usually take care if this themselves.

One exception to this is in signal handlers: L<Term::CLI> calls these
methods during its signal handling.

=item B<get_screen_size>
X<get_screen_size>

Use C<Term::ReadKey::GetTerminalSize> to get the appropriate
dimensions and return them is (I<height>, I<width>).

=back

=head1 CLASS METHODS

=over

=item B<term>
X<term>

Return the latest C<Term::CLI::ReadLine> object created.

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::ReadLine>(3p),
L<Term::ReadLine::Gnu>(3p),
L<Term::ReadLine::Perl>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018-2021.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
