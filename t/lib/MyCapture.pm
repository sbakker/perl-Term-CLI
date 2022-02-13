#===============================================================================
#
#       Module:  MyCapture
#  Description:  Implement workarounds for weird Capture::Tiny behaviour on
#                OpenBSD 7.0
#
#       Author:  Steven Bakker (SB), <sbakker@cpan.org>
#      Created:  13 February 2022
#
#   Copyright (c) 2022 Steven Bakker <sbakker@cpan.org>; All rights reserved.
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#===============================================================================

package MyCapture;

use 5.014;
use parent qw( Exporter );

BEGIN {
    our $VERSION     = '1.00';

	our @EXPORT_OK   = qw(
        my_capture
        my_stdout_like my_stderr_like
        my_combined_is
    );
	our @EXPORT      = ();
	our %EXPORT_TAGS = ( all => \@EXPORT_OK );
}

# Work around i386 OpenBSD issue with Capture::Tiny: `capture` fails on the
# third call.

use Capture::Tiny qw( capture );
use Test::More;
use Test::Output;

sub my_combined_is {
    my ($code, $expected, $name) = @_;

    open my $old_stdout, '>&STDOUT' or die "cannot dup STDOUT: $!";
    open my $old_stderr, '>&STDERR' or die "cannot dup STDERR $!";
    
    my $result = combined_is(sub { $code->() }, $expected, $name);

    open STDOUT, '>&', $old_stdout;
    open STDERR, '>&', $old_stderr;

    return $result;
}

sub my_stdout_like {
    my ($code, $regex, $name) = @_;

    open my $old_stdout, '>&STDOUT' or die "cannot dup STDOUT: $!";
    open my $old_stderr, '>&STDERR' or die "cannot dup STDERR $!";
    
    my $result = stdout_like(sub { $code->() }, $regex, $name);

    open STDOUT, '>&', $old_stdout;
    open STDERR, '>&', $old_stderr;

    return $result;

    #my ($stdout) = my_capture($code);
    #like($stdout, $regex, $name);
}

sub my_stderr_like {
    my ($code, $regex, $name) = @_;

    open my $old_stdout, '>&STDOUT' or die "cannot dup STDOUT: $!";
    open my $old_stderr, '>&STDERR' or die "cannot dup STDERR $!";
    
    my $result = stderr_like(sub { $code->() }, $regex, $name);

    open STDOUT, '>&', $old_stdout;
    open STDERR, '>&', $old_stderr;

    return $result;
}

sub my_capture {
    my ($code) = @_;

    open my $old_stdout, '>&STDOUT' or die "cannot dup STDOUT: $!";
    open my $old_stderr, '>&STDERR' or die "cannot dup STDERR $!";
    
    my ($stdout, $stderr, @result) = capture( sub { $code->() } );

    open STDOUT, '>&', $old_stdout;
    open STDERR, '>&', $old_stderr;

    return ($stdout, $stderr, @result);
}

1;

__END__

=pod

=head1 NAME

MyCapture - compensate for Capture::Tiny bugs

=head1 SYNOPSIS

 use MyCapture qw( my_capture my_stdout_like );

 my ($stdout, $stderr, $code)
    = my_capture( sub { say "out"; say STDERR "err"; return 42 } );

 say "out=$stdout";  # prints "out=out"
 say "err=$stderr";  # prints "err=out"
 say "answer=$code"; # prints "answer=42"

 use Test::More tests => 1;

 my_stdout_like(
    sub { system("date") },
    qr{ \d\d : \d\d : \d\d }xms,
    '"date" output includes timestamp'
 );

=head1 DESCRIPTION

On OpenBSD 7.0 for i386, the 0.48 version of L<Capture::Tiny|Capture::Tiny>
has a bug that C<capture> to run successfully two times, but will cause it to
crash the third time.

The dirty fix is to wrap C<capture> (and L<Test::Output|Test::Output>'s
C<stdout_like>) with a function that makes sure that the F<STDOUT>/F<STDERR>
file handles are saved and restored before and after the call to C<capture>,
respectively.

=head1 FUNCTIONS

=over

=item B<my_capture> ( I<CODE> )

    ( STDOUT, STDERR, RESULT ) = my_capture( CODE );

Similar to C<capture>, except that I<CODE> must be a proper C<sub{}> block.

=item B<my_stdout_like> ( I<CODE>, I<REGEX>, I<NAME> )

Same as C<stdout_like>.

=item B<my_stderr_like> ( I<CODE>, I<REGEX>, I<NAME> )

Same as C<stderr_like>.

=item B<my_combined_is> ( I<CODE>, I<EXPECTED>, I<NAME> )

Same as C<combined_is>.

=back

=head1 SEE ALSO

L<Capture::Tiny|Capture::Tiny>(3),
L<Test::Output|Test::Output>(3),

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>; 2022.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Steven Bakker <sbakker@cpan.org>; All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
