#===============================================================================
#
#       Module:  Term::CLI::Version
#         File:  Version.pm
#
#        Notes:  Global version for all Term::CLI modules.
#       Author:  Steven Bakker (SB), <Steven.Bakker@ams-ix.net>
#      Created:  07/Feb/2018
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

package Term::CLI::Version;

use Modern::Perl;

our $VERSION = '1.11';

sub import {
    my $class = shift;
    my @symbols = @_;
    if (grep { $_ eq '$VERSION' or $_ eq ':all' } @symbols) {
        my $caller = caller();
        no strict 'refs';
        my $v = $VERSION;
        *{$caller.'::VERSION'} = \$v;
    }
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Version - global version for Term::CLI and sub modules

=head1 SYNOPSIS

    package Term::CLI::Foo;
    use Term::CLI::Version qw( $VERSION );

    say $VERSION;
    1;

=head1 DESCRIPTION

Define a I<$VERSION> for the whole L<Term::CLI|/Term::CLI>(3p) library.
This provides a single, consistent version string that can be used in
(sub-)classes.

The module has one "importable" symbol, I<$VERSION>. Upon import, however,
this will not alias the module's I<$VERSION> into the caller's namespace, but
instead assign its own I<$VERSION> to a I<$VERSION> variable in the caller's
namespace.

=head1 VARIABLES

=over

=item I<$VERSION>
X<$VERSION>

Version string for the library. Not exported by default.

=back

=head1 EXAMPLES

The following example shows how to use the module, and how it creates a copy
of the I<$VERSION> variable, rather than an alias.

    # --- M6/My/Foo.pm ---
    package Term::CLI::Foo;

    use Term::CLI::Version qw( $VERSION );

    # --- foo.pl ---
    use Term::CLI::Version;
    use Term::CLI::Foo;

    say $Term::CLI::Foo::VERSION;     # Will print 1.09

    $Term::CLI::VERSION = '666';

    say $Term::CLI::Version->version; # Will still print 1.09

=head1 SEE ALSO

L<Term::CLI|/Term::CLI>(3p).

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
