#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Seed::Response' );
}

diag( "Testing Seed::Response $Seed::Response::VERSION, Perl $], $^X" );
