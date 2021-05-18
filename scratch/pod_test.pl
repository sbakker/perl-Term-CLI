#!/usr/bin/env perl
use 5.014;
use warnings;

use Pod::Simple;
use Pod::Text::Termcap;

my $formatted;
my $parser = Pod::Text::Termcap->new( width => 39 );
$parser->output_string(\$formatted);

my $usage_1 = "B<file> {B<cp>|B<info>|B<mv>}";
my $summary = "Perform various file operations";

$parser->parse_string_document(<<EOF);
=over 40

=item $usage_1

$summary

=back
EOF

$formatted =~ s/\n+$//s;
$formatted =~ s/^\s+//s;
print "$formatted\n";

$formatted = '';
$parser = Pod::Text::Termcap->new( width => 39 );
$parser->output_string(\$formatted);

my @usage_2 = (
    "B<file> [B<--verbose>] {B<cp>|B<info>|B<mv>}",
    "B<file> [B<-v>] {B<cp>|B<info>|B<mv>}",
);

my $description =<<EOF;
Perform various file operations, depending on the sub-command
given.
EOF

my $text = "=head2 Usage:\n\n=over\n\n"
        . join("", map { "=item $_\n\n" } @usage_2)
        . "=back\n\n"
        . "=head2 Description:\n\n"
        . $description;

$parser->parse_string_document($text);
#$formatted =~ s/\n+$//s;
#$formatted =~ s/^\s+//s;
print "---\n";
print "$formatted\n";
print "---\n";
print "$text";
