#!/usr/bin/perl -T

use 5.014_001;
use Modern::Perl;

package Term_CLI_Element_test;

use parent qw( Test::Class );

use Test::More;
use FindBin;
use Term::CLI::Argument;

my $ELT_NAME = 'test_elt';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $elt = Term::CLI::Element->new(name => $ELT_NAME);

    isa_ok( $elt, 'Term::CLI::Element', 'Term::CLI::Element->new' );
    $self->{arg} = $elt;
}

sub check_attributes: Test(1) {
    my $self = shift;
    my $elt = $self->{arg};
    is( $elt->name, $ELT_NAME, "name attribute is $ELT_NAME" );
}

sub check_error: Test(2) {
    my $self = shift;
    my $elt = $self->{arg};

    ok( ! defined $elt->set_error('ERROR'), 'set_error returns undef' );
    is( $elt->error, 'ERROR', "error is ERROR");
}

sub check_complete: Test(1) {
    my $self = shift;
    my $elt = $self->{arg};

    ok( ! defined $elt->complete('FOO'), 'no completions for "FOO"' );
}

#sub get_contract_info_without_results: Test(2) {
    #my $self = shift;
    #my $my = $self->{my};
    #my $info = $my->get_contract_info(contract_handle => 'xamsnoc');
    #is( $info, undef, 'result is <undef>' );
    #like($my->error, qr/no contracts found/i, 'error diagnostic');
#}

package main;

Term_CLI_Element_test->SKIP_CLASS(
    ($::ENV{SKIP_ELEMENT})
        ? "disabled in environment"
        : 0
);
Term_CLI_Element_test->runtests();
