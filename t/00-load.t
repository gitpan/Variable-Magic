#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Variable::Magic' );
}

diag( "Testing Variable::Magic $Variable::Magic::VERSION, Perl $], $^X" );
