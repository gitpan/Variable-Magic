#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard get => sub { ++$c };
ok($c == 0, 'get : create wizard');

my $n = int rand 1000;
my $a = $n;

cast $a, $wiz;
ok($c == 0, 'get : cast');

my $b = $a;
ok($c == 1, 'get : assign to');
ok($b == $n, 'get : assign to correctly');

$b = "X${a}Y";
ok($c == 2, 'get : interpolate');
ok($b eq "X${n}Y", 'get : interpolate correctly');
