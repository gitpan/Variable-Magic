#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

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
my $n = sub { ++$x };
my $a = $n;

cast $a, $wiz;
check('code : cast');

my $b = $a;
++$x[0];
check('code : assign to');

$b = "X${a}Y";
++$x[0];
check('code : interpolate');

$b = \$a;
check('code : reference');

$a = $n;
++$x[1];
check('code : assign');

$a->();
check('code : call');

{
 my $b = $n;
 cast $b, $wiz;
}
++$x[4];
check('code : scope end');

undef $a;
++$x[1];
check('code : undef');

dispell $a, $wiz;
check('code : dispell');
