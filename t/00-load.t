#!perl -T

use strict;
use warnings;

use Config;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Variable::Magic' );
}

my $p = $Config::Config{perl_patchlevel};
$p = $p ? 'patchlevel ' . int $p : 'no patchlevel';
diag( "Testing Variable::Magic $Variable::Magic::VERSION, Perl $] ($p), $^X" );
