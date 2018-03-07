#===============================================================================
#
#       Module:  Term::CLI::L10N::en
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  27/02/18
#
#   Copyright (c) 2018 AMS-IX B.V.; All rights reserved.
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

package Term::CLI::L10N::en  0.03002 {

use Modern::Perl;

use parent qw( Term::CLI::L10N );

our %Lexicon = (
    _AUTO => 1,
);

}

1;

__END__

=pod

=head1 NAME

Term::CLI::L10N::en - English localizations for Term::CLI

=head1 SYNOPSIS

 use Term::CLI::L10N;

 loc("invalid value");

=head1 DESCRIPTION

=head1 VARIABLES

=over 

=item <%LEXICON>

Package variable containing the language mappings.

=back

=head1 SEE ALSO

L<Locale::Maketext>(3p),
L<Term::CLI::L10N>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, AMS-IX B.V.; 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 AMS-IX B.V.; All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


