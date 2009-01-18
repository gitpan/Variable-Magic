#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

use Variable::Magic qw/wizard cast VMG_COMPAT_SCALAR_LENGTH_NOLEN/;

my $c = 0;

my $n = 1 + int rand 1000;
my $wiz = wizard len => sub { ++$c; return $n };
is $c, 0, 'len: wizard() doesn\'t trigger magic';

my @a = qw/a b c/;

$c = 0;
cast @a, $wiz;
is $c, 0, 'len: cast on array doesn\'t trigger magic';

$c = 0;
my $b = scalar @a;
is $c, 1,  'len: get array length triggers magic correctly';
is $b, $n, 'len: get array length correctly';

$c = 0;
$b = $#a;
is $c, 1,      'len: get last array index triggers magic correctly';
is $b, $n - 1, 'len: get last array index correctly';

$n = 0;

$c = 0;
$b = scalar @a;
is $c, 1, 'len: get array length 0 triggers magic correctly';
is $b, 0, 'len: get array length 0 correctly';

SKIP: {
 skip 'length() no longer calls mg_len magic' => 5 if VMG_COMPAT_SCALAR_LENGTH_NOLEN;

 $c = 0;
 $n = 1 + int rand 1000;
 # length magic on scalars needs also get magic to be triggered.
 $wiz = wizard get => sub { return 'anything' },
               len => sub { ++$c; return $n };

 my $x = int rand 1000;

 $c = 0;
 cast $x, $wiz;
 is $c, 0, 'len: cast on scalar doesn\'t trigger magic';

 $c = 0;
 $b = length $x;
 is $c, 1,  'len: get scalar length triggers magic correctly';
 is $b, $n, 'len: get scalar length correctly';

 $n = 0;

 $c = 0;
 $b = length $x;
 is $c, 1,  'len: get scalar length 0 triggers magic correctly';
 is $b, $n, 'len: get scalar length 0 correctly';
}
