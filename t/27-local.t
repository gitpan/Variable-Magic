#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast MGf_LOCAL/;

if (MGf_LOCAL) {
 plan tests => 5;
} else {
 plan skip_all => 'No local magic for this perl';
}

my $c = 0;
my $wiz = wizard 'local' => sub { ++$c };
is($c, 0, 'local : create wizard');

local $a = int rand 1000;
my $res = cast $a, $wiz;
ok($res,  'local : cast succeeded');
is($c, 0, 'local : cast didn\'t triggered the callback');

{
 local $a;
 is($c, 1, 'local : localized');
}
is($c, 1, 'local : end of local scope');
