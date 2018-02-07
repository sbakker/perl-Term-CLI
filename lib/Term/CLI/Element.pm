#===============================================================================
#
#       Module:  Term::CLI::Element
#
#  Description:  Generic parent class for elements in Term::CLI
#
#       Author:  Steven Bakker (SB), <sb@monkey-mind.net>
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

package Term::CLI::Element {

use Modern::Perl;
use Term::CLI::Version qw( $VERSION );
use Term::CLI::ReadLine;

use Moo;
use namespace::clean;

has name    => ( is => 'ro', required => 1 );
has error   => ( is => 'rwp', default => sub {''} );

sub term { return Term::CLI::ReadLine->term }

sub set_error {
    my ($self, @value) = @_;
    if (!@value or !defined $value[0]) {
        $self->_set_error('');
    }
    else {
        $self->_set_error(join('', @value));
    }
    return;
}

sub complete { return () }

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Element - generic parent class for elements in Term::CLI

=head1 SYNOPSIS

 use Term::CLI::Element;

 my $arg = Term::CLI::Element->new(name => 'varname');

=head1 DESCRIPTION

Generic parent class for elements in L<Term::CLI>(3p). This is used
by L<Term::CLI::Command>(3p) and L<Term::CLI::Argument>(3p) to provide
basic, shared functionality.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new Term::CLI::Element object and return a reference to it.

The B<name> attribute is required.

=back

=head1 METHODS

=head2 Accessors

=over

=item B<error> (I<STRING>, read-only)

Contains a diagnostic message in case of errors.

=item B<name> (I<STRING>, read-only)

Element name. Can be any string, but must be specified at construction
time.

=item B<term> (read-only)

The active L<Term::CLI::ReadLine> object.

=back

=head2 Other

=over

=item B<set_error> ( I<STRING>, ... )

Set the L<error|/error>() attribute to the concatenation of all I<STRING> parameters
and return a "failure" (C<undef> or the empty list, depending on call context).

=item B<complete> ( I<STR> )

Return a list of strings that are possible completions for I<value>.
By default, this method returns an empty list.

Sub-classes should probably override this.

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::CLI::Command>(3p),
L<Term::CLI::ReadLine>(3p),
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
