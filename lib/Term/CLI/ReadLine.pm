#=============================================================================
#
#       Module:  Term::CLI::ReadLine
#
#  Description:  Class for Term::CLI and Term::ReadLine glue
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  23/01/18
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

#BEGIN { $::ENV{PERL_RL} = 'Gnu' }

use parent 0.228 qw( Term::ReadLine );

use Term::ReadKey ();

use namespace::clean 0.25;

my $Term = undef;

sub new {
    my $class = shift;
    $Term = Term::ReadLine->new(@_);
    my $rlmodule = lc $Term->ReadLine =~ s/.*Term::ReadLine:://r;
    if (0 && $rlmodule ne 'gnu' && $rlmodule ne 'perl') {
        my $err = "** No 'Term::ReadLine::Gnu' support loaded\n";
        if ($::ENV{PERL_RL} && lc $::ENV{PERL_RL} ne 'gnu') {
            $err .= "** Either unset the PERL_RL environment"
                 .  " variable or set it to 'Gnu'\n";
        }
        else {
            $err .= "** Make sure the Term::ReadLine::Gnu module is installed"
                 .  " and either unset the\n"
                 .  "** PERL_RL environment variable or set it to 'Gnu'\n";
        }
        confess $err;
    }
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

sub readline {
    my ($self, $prompt) = @_;

    my %old_sig = $self->_set_signal_handlers;

    my $input = $self->SUPER::readline($prompt);

    %SIG = %old_sig; # Restore signal handlers.
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
        *{stifle_history} =
        *{deprep_terminal} =
        *{forced_update_display} = sub { };

        return $self;
    }

    *{replace_line} = \&_perl_replace_line;
    *{prep_terminal} = \&_perl_prep_terminal;
    *{stifle_history} = \&_perl_stifle_history;
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

sub _perl_stifle_history {
    my ($self, $max) = @_;
    return if $max <= 0;
    $readline::rl_MaxHistorySize = $max;
    my $cur = int @readline::rl_History;
    if ($cur > $max) {
        splice(@readline::rl_History, 0, -$max);
        $readline::rl_HistoryIndex -= ($cur - $max);
    }
    return;
}

}
1;

__END__

=pod

=head1 NAME

Term::CLI::ReadLine - maintain a single Term::ReadLine object

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

Even though L<Term::ReadLine>(3p) has an object-oriented interface,
the L<Term::ReadLine::Gnu>(3p) library really only keeps a single
instance around (if you create multiple L<Term::ReadLine> objects,
all parameters and history are shared).

This class inherits from L<Term::ReadLine> and keeps a single
instance around with a class accessor to access that single instance.

It also generates stubs for some methods if the underlying module is
not L<Term::ReadLine::Gnu>.

=head1 CONSTRUCTORS

=over

=item B<new> ( ... )
X<new>

Create a new L<Term::CLI::ReadLine>(3p) object and return a reference to it.

 Check that the newly created newly created L<Term::ReadLine> object is
 of the L<Term::ReadLine::Gnu>(3p) variety. If not, it will call throw a fatal
 exception (using L<Carp::confess|Carp/confess>).

Arguments are identical to L<Term::ReadLine>(3p) and
L<Term::ReadLine::Gnu>(3p).

A reference to the newly created object is stored internally and can be
retrieved later with the L<term|/term> class method. Note that repeated calls
to C<new> will reset this internal reference.

=back

=head1 METHODS

See L<Term::ReadLine>(3p) and L<Term::ReadLine::Gnu>(3p) for the
inherited methods.

=over

=item B<echo_signal_char> ( I<signal> )
X<echo_signal_char>

Wrapper around the method of the same name in L<Term::ReadLine::Gnu>. This
method also accepts a signal name instead of a signal number. It only
works for C<INT> (2), C<QUIT> (3), and C<TSTP> (20) signals as these are
the only ones that can be entered from a keyboard.

=item B<readline> ( I<prompt> )
X<readline>

Wrap around the original L<Term::ReadLine's readline|Term::ReadLine/readline>
with custom signal handling, see the
L<CAVEATS section in Term::CLI|Term::CLI/CAVEATS>

=item B<term_width>
X<term_width>

Return the width of the terminal in characters, as given by
L<Term::ReadLine>.

=item B<term_height>
X<term_height>

Return the height of the terminal in characters, as given by
L<Term::ReadLine>.

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

=item B<stifle_history> ( I<max_lines> )
X<stifle_history>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to cap the size of the history.

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

L<Term::CLI>(3p).
L<Term::ReadLine>(3p),
L<Term::ReadLine::Gnu>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
