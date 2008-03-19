#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

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
check('scalar : create wizard');

my $n = int rand 1000;
my $a = $n;

cast $a, $wiz;
check('scalar : cast');

my $b = $a;
++$x[0];
check('scalar : assign to');

$b = "X${a}Y";
++$x[0];
check('scalar : interpolate');

$b = \$a;
check('scalar : reference');

$a = 123;
++$x[1];
check('scalar : assign');

++$a;
++$x[0]; ++$x[1];
check('scalar : increment');

--$a;
++$x[0]; ++$x[1];
check('scalar : decrement');

$a *= 1.5;
++$x[0]; ++$x[1];
check('scalar : multiply');

$a /= 1.5;
++$x[0]; ++$x[1];
check('scalar : divide');

{
 my $b = $n;
 cast $b, $wiz;
}
++$x[4];
check('scalar : scope end');

undef $a;
++$x[1];
check('scalar : undef');

dispell $a, $wiz;
check('scalar : dispell');
