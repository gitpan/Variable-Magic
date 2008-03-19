#!perl -T

use strict;
use warnings;

use Test::More tests => 21;

use Variable::Magic qw/wizard cast dispell VMG_COMPAT_ARRAY_PUSH_NOLEN VMG_COMPAT_ARRAY_UNDEF_CLEAR/;

my @c = (0) x 12;
my @x = (0) x 12;

sub check {
 is join(':', map { (defined) ? $_ : 'u' } @c[0 .. 11]),
    join(':', map { (defined) ? $_ : 'u' } @x[0 .. 11]),
    $_[0];
}

my $wiz = wizard get   => sub { ++$c[0] },
                 set   => sub { ++$c[1] },
                 len   => sub { ++$c[2]; $_[2] },
                 clear => sub { ++$c[3] },
                 free  => sub { ++$c[4] },
                 copy  => sub { ++$c[5] },
                 dup   => sub { ++$c[6] },
                 local => sub { ++$c[7] },
                 fetch => sub { ++$c[8] },
                 store => sub { ++$c[9] },
                 'exists' => sub { ++$c[10] },
                 'delete' => sub { ++$c[11] };
check('array : create wizard');

my @n = map { int rand 1000 } 1 .. 5;
my @a = @n;

cast @a, $wiz;
check('array : cast');

my $b = $a[2];
check('array : assign element to');

my @b = @a;
++$x[2];
check('array : assign to');

$b = "X@{a}Y";
++$x[2];
check('array : interpolate');

$b = \@a;
check('array : reference');

@b = @a[2 .. 4];
check('array : slice');

@a = qw/a b d/;
$x[1] += 3; ++$x[3];
check('array : assign');

$a[2] = 'c';
check('array : assign old element');

$a[3] = 'd';
++$x[1];
check('array : assign new element');

push @a, 'x';
++$x[1]; ++$x[2] unless VMG_COMPAT_ARRAY_PUSH_NOLEN;
check('array : push');

pop @a;
++$x[1]; ++$x[2];
check('array : pop');

unshift @a, 'x';
++$x[1]; ++$x[2];
check('array : unshift');

shift @a;
++$x[1]; ++$x[2];
check('array : shift');

$b = @a;
++$x[2];
check('array : length');

@a = map ord, @a; 
$x[1] += 4; ++$x[2]; ++$x[3];
check('array : map');

@b = grep { defined && $_ >= ord('b') } @a;
++$x[2];
check('array : grep');

for (@a) { }
$x[2] += 5;
check('array : for');

{
 my @b = @n;
 cast @b, $wiz;
}
++$x[4];
check('array : scope end');

undef @a;
++$x[3] if VMG_COMPAT_ARRAY_UNDEF_CLEAR;
check('array : undef');

dispell @a, $wiz;
check('array : dispel');
