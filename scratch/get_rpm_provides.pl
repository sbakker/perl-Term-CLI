#!/usr/bin/perl
# ============================================================================
#
#         File:  get_rpm_provides.pl
#
#        Usage:  get_rpm_provides.pl lib/**/*.pm
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  10/03/18
#
#   Copyright (c) 2018 Steven Bakker; All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic".
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# ============================================================================

use 5.014_001;
use warnings;
use strict;

my $pkgname;
my $version;

@ARGV || die "usage: get_rpm_provides.pl pm-file ...\n";

for my $fname (@ARGV) {
    if (open my $fh, '<', $fname) {
        my $in_pod = 0;
        my $pkgname;
        my $version;

        while (<$fh>) {
            last if /^__END__$/ or /^__DATA__$/;
            if ($in_pod) {
                if (/^=cut/) {
                    $in_pod = 0;
                }
                next;
            }
            elsif (/^=(pod|head|over|item|back|begin|end|for|encoding)/) {
                $in_pod++;
                next;
            }

            if (/^package\s+([\w:]+)\s+([\d\.\_]+)/) {
                print_pkg($pkgname, $version);
                print_pkg($1, $2);
            }
            elsif (/^\s*package\s+([\w:]+)/) {
                print_pkg($pkgname, $version);
                $pkgname = $1;
            }
            elsif (/^\s*(?:our\s+)?\$VERSION\s*=\s*(['"]?)([\d\._]+)\1/) {
                print_pkg($pkgname, $2);
            }
        }
        close $fh;
        print_pkg($pkgname, $version);
    }
    else {
        say STDERR "Cannot read $fname: $!";
    }
}

sub print_pkg {
    my ($name, $vers) = @_;
    if (defined $name) {
        $vers //= 0;
        say "Provides:       perl($name) = $vers";
    }
    $pkgname = undef;
    $version = undef;
}
