#!/usr/bin/perl -T

use 5.014_001;
use Modern::Perl;

sub Main() {
    Term_CLI_Argument_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_test->runtests();
}

package Term_CLI_Argument_test {

use parent qw( Test::Class );

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

sub check_validate: Test(8) {
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

    ok( !$arg->validate(), "() does not validate");

    is ( $arg->error, 'value cannot be empty',
        "error on () value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( $arg->validate('thing'), "'thing' validates");

    is ( $arg->error, '',
        "error is cleared on successful validation" );
}

}

Main();
