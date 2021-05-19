#===============================================================================
#
#       Module:  Term::CLI::PerlFeatures
#
#  Description:  Turn on modern-ish Perl features
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  18/May/2021
#
#   Copyright (c) 2021 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#===============================================================================

package Term::CLI::PerlFeatures  0.052002 {

    use strict;
    use warnings;

    use feature ();

    sub import {
        warnings->import;
        strict->import;
        feature->import( ':5.14' );
    }

    sub unimport {
        warnings->unimport;
        strict->unimport;
        feature->unimport;
    }
}

1;

__END__

=pod

=head1 NAME

Term::CLI::PerlFeatures - turn on modern-ish Perl features

=head1 SYNOPSIS

Instead of:

  use 5.014_001; # use strict is implicit
  use warnings;

Or:

  use Modern::Perl '2012';

Write:

  use Term::CLI::PerlFeatures;

=head1 DESCRIPTION

This module provides a simplified alternative to
L<Modern::Perl|Modern::Perl>(3p). It provides the equivalent of
C<use Modern::Perl '2012'> sans L<mro|mro>(3p), while avoiding a
dependency on an external module.

It just turns on perl 5.14 features (which automatically turns on
C<strict>), and makes sure C<warnings> is set as well.

Since multiple inheritance is not used in L<Term::CLI>, we don't
need to depend on L<mro|mro>(3p), so L<Modern::Perl|Modern::Perl>(3p)
is overkill.

=head1 SEE ALSO

L<feature|feature>(3p),
L<Modern::Perl|Modern::Perl>(3p),
L<mro|mro>(3p).

=head1 AUTHOR

Steven Bakker (SBAKKER) E<lt>sbakker@cpan.orgE<gt>, 2021.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021 Steven Bakker

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

=item import

=item unimport

=back

=end __PODCOVERAGE
