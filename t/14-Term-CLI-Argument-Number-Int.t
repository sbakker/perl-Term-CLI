#!/usr/bin/perl -T

use 5.014_001;
use strict;
use Modern::Perl;

sub Main {
    Term_CLI_Argument_Number_Int_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_Number_Int_test->runtests();
}

package Term_CLI_Argument_Number_Int_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI::ReadLine;
use Term::CLI::Argument::Number::Int;
use File::Temp qw( tempdir );

my $ARG_NAME  = 'test_int';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $arg = Term::CLI::Argument::Number::Int->new(
        name => $ARG_NAME,
    );

    isa_ok( $arg, 'Term::CLI::Argument::Number::Int',
            'Term::CLI::Argument::Number::Int->new' );

    $self->{arg} = $arg;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::Number::Int->new() }
        qr/Missing required arguments: name/,
        'error on missing name';
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'Number::Int', "type attribute is Number::Int" );
}

sub check_validate: Test(17) {
    my $self = shift;
    my $arg = $self->{arg};

    my $test_value = '+1200';
    my $expected   = 1200;
    my $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is( $value, $expected, "'$test_value' => $value (equal to $expected)" );

    $test_value = '-2';
    $expected   = -2;
    $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is( $value, $expected, "'$test_value' => $value (equal to $expected)" );

    $test_value = '2.5';
    $value      = $arg->validate($test_value);
    ok( ! defined $value, "'$test_value' should not validate" );
    is( $arg->error, 'not a valid number',
        'error message on validate -> "not a valid number"' );

    my $min = -10;
    my $max = 10;
    $test_value = '4';
    $arg->min($min);
    $arg->max($max);
    $arg->inclusive(1);

    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value <= $max" )
    or diag("validation error: ".$arg->error);

    $test_value = $min;
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value <= $max" )
    or diag("validation error: ".$arg->error);

    $test_value = $max;
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value <= $max" )
    or diag("validation error: ".$arg->error);

    $arg->inclusive(0);

    $test_value = $min;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min < $test_value < $max" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

    $test_value = $max;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min < $test_value < $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );

    $arg->inclusive(1);

    $test_value = $min-1;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value <= $max" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

    $test_value = $max+1;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value <= $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );
}

}

Main();
