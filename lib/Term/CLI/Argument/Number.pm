#===============================================================================
#
#       Module:  Term::CLI::Argument::Number
#
#  Description:  Base class for numerical arguments in Term::CLI
#
#       Author:  Steven Bakker (SB), <Steven.Bakker@ams-ix.net>
#      Created:  22/01/18
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

package Term::CLI::Argument::Number {

use Modern::Perl;
use Moo;
use namespace::clean;

extends 'Term::CLI::Argument';

has min => ( is => 'ro', predicate => 1 );
has max => ( is => 'ro', predicate => 1 );
has inclusive => ( is => 'ro', default => sub {1} );

sub coerce_value {
    die "coerce_value() has not been overloaded";
}

sub validate {
    my ($self, $value) = @_;

    if (!defined $value || length($value) == 0) {
        return $self->set_error('not a valid number');
        return;
    }

    my ($num, $unparsed) = $self->coerce_value($value);

    if ($unparsed) {
        return $self->set_error('not a valid number');
    }

    if ($self->inclusive) {
        if ($self->has_min && $num < $self->min) {
            return $self->set_error('too small');
        }
        elsif ($self->has_max && $num > $self->max) {
            return $self->set_error('too large');
        }
    }
    else {
        if ($self->has_min && $num <= $self->min) {
            return $self->set_error('too small');
        }
        elsif ($self->has_max && $num >= $self->max) {
            return $self->set_error('too large');
        }
    }
    return $num;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Number - base class for numerical arguments in Term::CLI

=head1 SYNOPSIS

 use Term::CLI::Argument::Number;

 my $arg = Term::CLI::Argument::Number->new(
                name => 'arg1',
                min => 1
                max => 2
                inclusive => 1
           );

=head1 DESCRIPTION

Base class for numerical arguments in L<Term::CLI>(3p). This class cannot
be used directly, but should be extended by sub-classes.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME>, ... )
X<new>

Create a new Term::CLI::Argument::Number object and return a reference
to it.

The B<name> attribute is required.

Other attributes that are recognised:

=over

=item B<min> =E<gt> I<NUM>

The minimum valid value (by default an I<inclusive> boundary,
but see L<inclusive|/inclusive> below.

=item B<max> =E<gt> I<NUM>

The maximum valid value (by default an I<inclusive> boundary,
but see L<inclusive|/inclusive> below.

=item B<inclusive> =E<gt> I<BOOLEAN>

Default is 1 (true). Indicates whether minimum/maximum boundaries
are inclusive or exclusive.

=back

=back

=head1 ACCESSORS

Inherited from L<Term::CLI::Argument>(3p). Additionally, the
following are defined:

=over

=item B<min>

=item B<max>

=item B<inclusive>

Read-only attributes, set at construction time (see L<new|/new> above.

=item B<has_min>

=item B<has_max>

Booleans, indicate whether C<min> and C<max> have been set, resp.

=back

=head1 METHODS

Inherited from L<Term::CLI::Argument>(3p).

Additionally:

=over

=item B<validate> ( I<VALUE> )

The L<validate|Term::CLI::Argument/validate> method uses the
L<coerce_value|/coerce_value> method to convert I<VALUE> to
a suitable number and then checks any boundaries.

=item B<coerce_value> ( I<VALUE> )

This method I<must> be overridden by sub-classes.

Its function interface should be identical to that of L<POSIX>'s C<strtod>
and C<strtol> functions. It will be called with a single argument (the
I<VALUE>) and is supposed to return a list of two values: the converted
number and the number of unparsed characters in I<VALUE>.

=back

=head1 SEE ALSO

L<POSIX>(3p),
L<Term::CLI::Argument>(3p),
L<Term::CLI>(3p).

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
