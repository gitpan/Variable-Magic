#!perl -T

use Test::More tests => 6;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $n = int rand 1000;
my $wiz = wizard len => sub { ++$c; return $n };
ok($c == 0, 'len : create wizard');

my @a = qw/a b c/;

cast @a, $wiz;
ok($c == 0, 'len : cast');

my $b = scalar @a;
ok($c == 1, 'len : get length');
ok($b == $n, 'len : get length correctly');

$n = 0;
$b = scalar @a;
ok($c == 2, 'len : get length 0');
ok($b == 0, 'len : get length 0 correctly');
