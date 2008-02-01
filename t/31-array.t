#!perl -T

use strict;
use warnings;

use Test::More tests => 21;

use Variable::Magic qw/wizard cast dispell/;

my @c = (0) x 12;
my @x = (0) x 12;

sub check {
 for (0 .. 11) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
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
ok(check(), 'array : create wizard');

my @n = map { int rand 1000 } 1 .. 5;
my @a = @n;

cast @a, $wiz;
ok(check(), 'array : cast');

my $b = $a[2];
ok(check(), 'array : assign element to');

my @b = @a;
++$x[2];
ok(check(), 'array : assign to');

$b = "X@{a}Y";
++$x[2];
ok(check(), 'array : interpolate');

$b = \@a;
ok(check(), 'array : reference');

@b = @a[2 .. 4];
ok(check(), 'array : slice');

@a = qw/a b d/;
$x[1] += 3; ++$x[3];
ok(check(), 'array : assign');

$a[2] = 'c';
ok(check(), 'array : assign old element');

$a[3] = 'd';
++$x[1];
ok(check(), 'array : assign new element');

push @a, 'x';
++$x[1]; ++$x[2] unless $^V && $^V gt 5.9.2; # since 5.9.3
ok(check(), 'array : push');

pop @a;
++$x[1]; ++$x[2];
ok(check(), 'array : pop');

unshift @a, 'x';
++$x[1]; ++$x[2];
ok(check(), 'array : unshift');

shift @a;
++$x[1]; ++$x[2];
ok(check(), 'array : shift');

$b = @a;
++$x[2];
ok(check(), 'array : length');

@a = map ord, @a; 
$x[1] += 4; ++$x[2]; ++$x[3];
ok(check(), 'array : map');

@b = grep { defined && $_ >= ord('b') } @a;
++$x[2];
ok(check(), 'array : grep');

for (@a) { }
$x[2] += 5;
ok(check(), 'array : for');

{
 my @b = @n;
 cast @b, $wiz;
}
++$x[4];
ok(check(), 'array : scope end');

undef @a;
++$x[3] if $^V && $^V gt 5.9.4; # since 5.9.5 - see #43357
ok(check(), 'array : undef');

dispell @a, $wiz;
ok(check(), 'array : dispel');
