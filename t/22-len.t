#!perl -T

use strict;
use warnings;

use Test::More tests => 11;

use Variable::Magic qw/wizard cast VMG_COMPAT_SCALAR_LENGTH_NOLEN/;

my $c = 0;
my $n = int rand 1000;
my $wiz = wizard len => sub { ++$c; return $n };
is($c, 0, 'len : create wizard');

my @a = qw/a b c/;

cast @a, $wiz;
is($c, 0, 'len : cast on array');

my $b = scalar @a;
is($c, 1,  'len : get array length');
is($b, $n, 'len : get array length correctly');

$b = $#a;
is($c, 2,      'len : get last array index');
is($b, $n - 1, 'len : get last array index correctly');

$n = 0;
$b = scalar @a;
is($c, 3, 'len : get array length 0');
is($b, 0, 'len : get array length 0 correctly');

$c = 0;
$n = int rand 1000;
# length magic on scalars needs also get magic to be triggered.
$wiz = wizard get => sub { return 56478 },
              len => sub { ++$c; return $n };

my $x = int rand 1000;

SKIP: {
 skip 'length() no longer calls mg_len magic', 3 if VMG_COMPAT_SCALAR_LENGTH_NOLEN;

 cast $x, $wiz;
 is($c, 0, 'len : cast on scalar');

 $b = length $x;
 is($c, 1,      'len : get scalar length');
 is($b, $n - 1, 'len : get scalar length correctly');
}
