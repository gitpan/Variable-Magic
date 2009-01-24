#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Variable::Magic' );
}

my $p = Variable::Magic::VMG_PERL_PATCHLEVEL;
$p = $p ? 'patchlevel ' . $p : 'no patchlevel';
diag( "Testing Variable::Magic $Variable::Magic::VERSION, Perl $] ($p), $^X" );

if ($^O eq 'MSWin32' && eval { require Win32; 1 }
                     && defined &Win32::BuildNumber) {
 diag "This is ActiveState Perl $] build " . Win32::BuildNumber();
}
