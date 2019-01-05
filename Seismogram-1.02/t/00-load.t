#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Seismogram::SAC' );
}

diag( "Testing Seismogram::SAC $Seismogram::SAC::VERSION, Perl $], $^X" );
