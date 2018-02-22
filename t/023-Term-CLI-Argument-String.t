#!/usr/bin/perl -T

use 5.014_001;
use strict;
use Modern::Perl;

sub Main {
    Term_CLI_Argument_String_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_String_test->runtests();
}

package Term_CLI_Argument_String_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI::Argument::String;

my $ARG_NAME= 'test_enum';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $arg = Term::CLI::Argument::String->new(
        name => $ARG_NAME,
    );

    isa_ok( $arg, 'Term::CLI::Argument::String',
            'Term::CLI::Argument::String->new' );
    $self->{arg} = $arg;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::String->new( name => $ARG_NAME) }
        qr/Missing required arguments: value_list/,
        'error on missing value_list';
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'String', "type attribute is String" );
}

sub check_complete: Test(1) {
    my $self = shift;
    my $arg = $self->{arg};

    my @expected = ();
    is_deeply( [$arg->complete('')], \@expected,
        "complete returns (@expected) for ''");
}

sub check_validate: Test(6) {
    my $self = shift;
    my $arg = $self->{arg};

    ok( !$arg->validate(undef), "'undef' does not validate");
    is ( $arg->error, 'value must be defined',
        "error on 'undef' value is set correctly" );

    $arg->set_error('SOMETHING');

    my $test_value = '';
    ok( $arg->validate($test_value), "'$test_value' validates");
    is ( $arg->error, '',
        "error is cleared on successful validation" );

    $arg->set_error('SOMETHING');

    my $test_value = 'a string';
    ok( $arg->validate($test_value), "'$test_value' validates");
    is ( $arg->error, '',
        "error is cleared on successful validation" );
}

}

Main();
