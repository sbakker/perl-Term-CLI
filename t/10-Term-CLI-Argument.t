#!/usr/bin/perl -T

use 5.014_001;
use Modern::Perl;

package Term_CLI_Argument_test;

use parent qw( Test::Class ) {

use Test::More;
use FindBin;
use Term::CLI::Argument;

my $ARG_NAME = 'test_arg';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $arg = Term::CLI::Argument->new(name => $ARG_NAME);

    isa_ok( $arg, 'Term::CLI::Argument', 'Term::CLI::Argument->new' );
    $self->{arg} = $arg;
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'GENERIC', "type attribute is GENERIC" );
}

sub check_validate: Test(6) {
    my $self = shift;
    my $arg = $self->{arg};

    ok( !$arg->validate(undef), "'undef' does not validate");

    is ( $arg->error, 'value cannot be empty',
        "error on 'undef' value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( !$arg->validate(''), "'' does not validate");
    is ( $arg->error, 'value cannot be empty',
        "error on '' value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( $arg->validate('thing'), "'thing' validates");

    is ( $arg->error, '',
        "error is cleared on successful validation" );
}

#sub get_contract_info_without_results: Test(2) {
    #my $self = shift;
    #my $my = $self->{my};
    #my $info = $my->get_contract_info(contract_handle => 'xamsnoc');
    #is( $info, undef, 'result is <undef>' );
    #like($my->error, qr/no contracts found/i, 'error diagnostic');
#}

}

Term_CLI_Argument_test->SKIP_CLASS(
    ($::ENV{SKIP_ARGUMENT})
        ? "disabled in environment"
        : 0
);
Term_CLI_Argument_test->runtests();
