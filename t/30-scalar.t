#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

use Variable::Magic qw/wizard cast dispell/;

my @c = (0) x 12;
my @x = (0) x 12;

sub check {
 for (0 .. 11) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
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
ok(check(), 'scalar : create wizard');

my $n = int rand 1000;
my $a = $n;

cast $a, $wiz;
ok(check(), 'scalar : cast');

my $b = $a;
++$x[0];
ok(check(), 'scalar : assign to');

$b = "X${a}Y";
++$x[0];
ok(check(), 'scalar : interpolate');

$b = \$a;
ok(check(), 'scalar : reference');

$a = 123;
++$x[1];
ok(check(), 'scalar : assign');

++$a;
++$x[0]; ++$x[1];
ok(check(), 'scalar : increment');

--$a;
++$x[0]; ++$x[1];
ok(check(), 'scalar : decrement');

$a *= 1.5;
++$x[0]; ++$x[1];
ok(check(), 'scalar : multiply');

$a /= 1.5;
++$x[0]; ++$x[1];
ok(check(), 'scalar : divide');

{
 my $b = $n;
 cast $b, $wiz;
}
++$x[4];
ok(check(), 'scalar : scope end');

undef $a;
++$x[1];
ok(check(), 'scalar : undef');

dispell $a, $wiz;
ok(check(), 'scalar : dispell');
