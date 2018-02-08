#===============================================================================
#
#       Module:  Term::CLI::Argument
#
#  Description:  Generic parent class for arguments in Term::CLI
#
#       Author:  Steven Bakker (SB), <sb@monkey-mind.net>
#      Created:  22/01/18
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

package Term::CLI::Argument {

our $VERSION = '1.00';

use Modern::Perl;
use Term::CLI::Version qw( $VERSION );
use Moo;

use Types::Standard qw( Int );

use namespace::clean;

extends 'Term::CLI::Element';

has min_occur => ( is => 'rw', isa => Int, default => sub{1});
has max_occur => ( is => 'rw', isa => Int, default => sub{1});

sub type {
    my $self = shift;
    my $class = ref $self;
    if ($class eq 'Term::CLI::Argument') {
        return 'GENERIC';
    }
    return $class =~ s/^Term::CLI::Argument:://r;
}

before validate => sub { $_[0]->set_error('') };

sub validate {
    my ($self, $value) = @_;

    $self->set_error('');
    if (!defined $value or $value eq '') {
        return $self->set_error("value cannot be empty");
    }
    return $value;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument - generic parent class for arguments in Term::CLI

=head1 SYNOPSIS

 use Term::CLI::Argument;

 my $arg = Term::CLI::Argument->new(name => 'varname');

=head1 DESCRIPTION

Generic parent class for arguments in L<Term::CLI>(3p).
Inherits from L<M6::CLI::Element>(3p).

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new Term::CLI::Argument object and return a reference to it.

The B<name> attribute is required.

=back

=head1 ACCESSORS

Accessors are inherited from L<Term::CLI::Element>(3p).

=head1 METHODS

=over

=item B<type>

Return the argument "type". By default, this is the object's class name
with the C<M6::CLI::Argument::> prefix removed. Can be overloaded to
provide a different value.

=item B<validate> ( I<value> )

Check whether I<value> is a valid value for this object. Return the
(possibly normalised) value if it is, nothing (i.e. C<undef> or the
empty list, depending on call context) if it is not (and set the
L<error|/error>() attribute).

By default, this method only checks whether I<value> is defined and not
an empty string.

Sub-classes should probably override this.

=back

=head1 SEE ALSO

L<Term::CLI::Argument::String>(3p),
L<Term::CLI::Argument::Number>(3p),
L<Term::CLI::Argument::Enum>(3p),
L<Term::CLI::Argument::Filename>(3p),
L<Term::CLI::Element>(3p),
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
