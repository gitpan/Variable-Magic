#!perl -T

use strict;
use warnings;

use Test::More tests => 33;

use Variable::Magic qw/wizard cast VMG_COMPAT_SCALAR_LENGTH_NOLEN/;

my $c = 0;

my $n = 1 + int rand 1000;
my $d;
my $wiz = wizard len => sub { $d = $_[2]; ++$c; return $n };
is $c, 0, 'len: wizard() doesn\'t trigger magic';

my @a = qw/a b c/;

$c = 0;
cast @a, $wiz;
is $c, 0, 'len: cast on array doesn\'t trigger magic';

$c = 0;
$d = undef;
my $b = scalar @a;
is $c, 1,  'len: get array length triggers magic correctly';
is $d, 3,  'len: get array length have correct default length';
is $b, $n, 'len: get array length correctly';

$c = 0;
$d = undef;
$b = $#a;
is $c, 1,      'len: get last array index triggers magic correctly';
is $d, 3,      'len: get last array index have correct default length';
is $b, $n - 1, 'len: get last array index correctly';

$n = 0;

$c = 0;
$d = undef;
$b = scalar @a;
is $c, 1, 'len: get array length 0 triggers magic correctly';
is $d, 3, 'len: get array length 0 have correct default length';
is $b, 0, 'len: get array length 0 correctly';

$n = undef;
@a = ();
cast @a, $wiz;

$c = 0;
$d = undef;
$b = scalar @a;
is $c, 1, 'len: get empty array length triggers magic correctly';
is $d, 0, 'len: get empty array length have correct default length';
is $b, 0, 'len: get empty array length correctly';

$c = 0;
$d = undef;
$b = $#a;
is $c, 1,  'len: get last empty array index triggers magic correctly';
is $d, 0,  'len: get last empty array index have correct default length';
is $b, -1, 'len: get last empty array index correctly';

SKIP: {
 skip 'length() no longer calls mg_len magic' => 16 if VMG_COMPAT_SCALAR_LENGTH_NOLEN;

 $c = 0;
 $n = 1 + int rand 1000;
 # length magic on scalars needs also get magic to be triggered.
 $wiz = wizard get => sub { return 'anything' },
               len => sub { $d = $_[2]; ++$c; return $n };

 my $x = 6789;

 $c = 0;
 cast $x, $wiz;
 is $c, 0, 'len: cast on scalar doesn\'t trigger magic';

 $c = 0;
 $d = undef;
 $b = length $x;
 is $c, 1,  'len: get scalar length triggers magic correctly';
 is $d, 4,  'len: get scalar length have correct default length';
 is $b, $n, 'len: get scalar length correctly';

 $n = 0;

 $c = 0;
 $d = undef;
 $b = length $x;
 is $c, 1,  'len: get scalar length 0 triggers magic correctly';
 is $d, 4,  'len: get scalar length 0 have correct default length';
 is $b, $n, 'len: get scalar length 0 correctly';

 $n = undef;
 $x = '';
 cast $x, $wiz;

 $c = 0;
 $d = undef;
 $b = length $x;
 is $c, 1, 'len: get empty scalar length triggers magic correctly';
 is $d, 0, 'len: get empty scalar length have correct default length';
 is $b, 0, 'len: get empty scalar length correctly';

 $x = "\x{20AB}ongs";
 cast $x, $wiz;

 {
  use bytes;

  $c = 0;
  $d = undef;
  $b = length $x;
  is $c, 1,  'len: get utf8 scalar length in bytes triggers magic correctly';
  is $d, 7,  'len: get utf8 scalar length in bytes have correct default length';
  is $b, $d, 'len: get utf8 scalar length in bytes correctly';
 }

 $c = 0;
 $d = undef;
 $b = length $x;
 is $c, 1,  'len: get utf8 scalar length triggers magic correctly';
 is $d, 5,  'len: get utf8 scalar length have correct default length';
 is $b, $d, 'len: get utf8 scalar length correctly';
}
