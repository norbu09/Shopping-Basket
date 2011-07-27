#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Shopping::Basket' ) || print "Bail out!\n";
}

diag( "Testing Shopping::Basket $Shopping::Basket::VERSION, Perl $], $^X" );
