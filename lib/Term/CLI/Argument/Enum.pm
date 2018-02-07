#===============================================================================
#
#       Module:  Term::CLI::Argument::Enum
#
#  Description:  Class for "enum" arguments in Term::CLI
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

package Term::CLI::Argument::Enum {

use Modern::Perl;
use List::Util qw( first );
use Term::CLI::Version qw( $VERSION );

use Moo;
use namespace::clean;

extends 'Term::CLI::Argument::String';

has value_list => (
    is => 'ro',
    isa => sub { die "$_[0] is not an ARRAY ref" if ref $_[0] ne 'ARRAY' },
    required => 1,
);

sub validate {
    my ($self, $value) = @_;

    $self->SUPER::validate($value) or return;

    if (first { $_ eq $value } @{$self->value_list}) {
        return $value;
    }
    else {
        return $self->set_error("not a valid value");
    }
}

sub complete {
    my ($self, $value) = @_;

    if (!length $value) {
        return @{$self->value_list};
    }
    else {
        return grep
                { substr($_, 0, length($value)) eq $value }
                @{$self->value_list};
    }
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Enum - class for "enum" string arguments in Term::CLI

=head1 SYNOPSIS

 use Term::CLI::Argument::Enum;

 my $arg = Term::CLI::Argument::Enum->new(
     name => 'arg1',
     value_list => [qw( foo bar baz )],
 );

=head1 DESCRIPTION

Class for "enum" string arguments in L<Term::CLI>(3p).

This class inherits from
the L<Term::CLI::Argument::String>(3p) class.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<STRING>, B<value_list> =E<gt> I<ARRAYREF> )

See also L<Term::CLI::Argument::String>(3p). The B<value_list> argument is
mandatory.

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument::String>(3p).

=over

=item B<value_list>

A reference to a list of valid values for the argument.

=back

=head1 METHODS

See also L<Term::CLI::Argument::String>(3p).

The following methods are added or overloaded:

=over

=item B<validate>

=item B<complete>

=back

=head1 SEE ALSO

L<Term::CLI::Argument::String>(3p),
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
