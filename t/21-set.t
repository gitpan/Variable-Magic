#!perl -T

use Test::More tests => 8;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard set => sub { ++$c };
ok($c == 0, 'get : create wizard');

my $a = 0;
cast $a, $wiz;
ok($c == 0, 'get : cast');

my $n = int rand 1000;
$a = $n;
ok($c == 1, 'set : assign');
ok($a == $n, 'set : assign correctly');

++$a;
ok($c == 2, 'set : increment');
ok($a == $n + 1, 'set : increment correctly');

--$a;
ok($c == 3, 'set : decrement');
ok($a == $n, 'set : decrement correctly');
