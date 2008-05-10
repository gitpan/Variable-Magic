#!perl -T

use strict;
use warnings;

use Test::More tests => 14;

use Variable::Magic qw/wizard cast dispell/;

my @c = (0) x 12;
my @x = (0) x 12;

sub check {
 is join(':', map { (defined) ? $_ : 'u' } @c[0 .. 11]),
    join(':', map { (defined) ? $_ : 'u' } @x[0 .. 11]),
    $_[0];
}

my $i = -1;
my $wiz = wizard get   => sub { ++$c[0] },
                 set   => sub { ++$c[1] },
                 len   => sub { ++$c[2] },
                 clear => sub { ++$c[3] },
                 free  => sub { ++$c[4] },
                 copy  => sub { ++$c[5] },
                 dup   => sub { ++$c[6] },
                 local => sub { ++$c[7] },
                 fetch => sub { ++$c[8] },
                 store => sub { ++$c[9] },
                 'exists' => sub { ++$c[10] },
                 'delete' => sub { ++$c[11] };
check('code : create wizard');

my $x = 0;
sub hlagh { ++$x };

cast &hlagh, $wiz;
check('code : cast');

hlagh();
check('code : call without arguments');
is($x, 1, 'code : call without arguments succeeded');

hlagh(1, 2, 3);
check('code : call with arguments');
is($x, 2, 'code : call with arguments succeeded');

undef *hlagh;
++$x[4];
check('code : undef symbol table');
is($x, 2, 'code : undef symbol table didn\'t call');

my $y = 0;
*hlagh = sub { ++$y };

cast &hlagh, $wiz;
check('code : re-cast');

my $r = \&hlagh;
check('code : take reference');

$r->();
check('code : call reference');
is($y, 1, 'code : call reference succeeded');
is($x, 2, 'code : call reference didn\'t triggered the previous code');

dispell &hlagh, $wiz;
check('code : dispell');
