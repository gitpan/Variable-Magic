#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard get => sub { ++$c };
is($c, 0, 'get : create wizard');

my $n = int rand 1000;
my $a = $n;

cast $a, $wiz;
is($c, 0, 'get : cast');

my $b = $a;
is($c, 1,  'get : assign to');
is($b, $n, 'get : assign to correctly');

$b = "X${a}Y";
is($c, 2,        'get : interpolate');
is($b, "X${n}Y", 'get : interpolate correctly');
