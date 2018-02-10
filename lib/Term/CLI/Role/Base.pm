#===============================================================================
#
#       Module:  Term::CLI::Role::Base
#
#  Description:  Generic roel for Term::CLI classes
#
#       Author:  Steven Bakker (SB), <sb@monkey-mind.net>
#      Created:  10/02/18
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
#===============================================================================

use 5.014_001;

package Term::CLI::Role::Base {

use Modern::Perl;
use Term::CLI::Version qw( $VERSION );
use Term::CLI::ReadLine;

use Moo::Role;

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

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Role::Base - generic role Term::CLI classes

=head1 SYNOPSIS

 package Term::CLI::Something {

    use Moo;

    with('Term::CLI::Role::Base');

    ...
 };

=head1 DESCRIPTION

Generic role for L<Term::CLI>(3p) classes. This role provides some
basic functions and attributes that all classes share.

=head1 METHODS

=head2 Accessors

=over

=item B<error> (I<STRING>, read-only)

Contains a diagnostic message in case of errors.

=item B<term> (read-only)

The active L<Term::CLI::ReadLine> object.

=back

=head2 Others

=over

=item B<set_error> ( I<STRING>, ... )

Set the L<error|/error>() attribute to the concatenation of all I<STRING> parameters
and return a "failure" (C<undef> or the empty list, depending on call context).

=back

=head1 SEE ALSO

L<Term::CLI::Element>(3p),
L<Term::CLI::ReadLine>(3p),
L<Term::CLI>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sb@monkey-mind.netE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
