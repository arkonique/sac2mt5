#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TauP' );
}

diag( "Testing TauP $TauP::VERSION, Perl $], $^X" );
