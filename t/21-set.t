#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard set => sub { ++$c };
is($c, 0, 'get : create wizard');

my $a = 0;
cast $a, $wiz;
is($c, 0, 'get : cast');

my $n = int rand 1000;
$a = $n;
is($c, 1,  'set : assign');
is($a, $n, 'set : assign correctly');

++$a;
is($c, 2,      'set : increment');
is($a, $n + 1, 'set : increment correctly');

--$a;
is($c, 3,  'set : decrement');
is($a, $n, 'set : decrement correctly');
