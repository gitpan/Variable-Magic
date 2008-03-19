#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast MGf_COPY/;

if (MGf_COPY) {
 plan tests => 1 + 8 + 14;
} else {
 plan skip_all => 'No copy magic for this perl' if !MGf_COPY;
}

my $c = 0;
my $wiz = wizard 'copy' => sub { ++$c };
is($c, 0, 'copy : create wizard');

SKIP: {
 eval "use Tie::Array";
 skip 'Tie::Array required to test copy magic on arrays', 8 if $@;

 tie my @a, 'Tie::StdArray';
 @a = (1 .. 10);

 my $res = cast @a, $wiz;
 ok($res,  'copy : cast on array succeeded');
 is($c, 0, 'copy : cast on array didn\'t triggered the callback');

 $a[3] = 13;
 is($c, 1, 'copy : callback triggers on array store');

 my $s = $a[3];
 is($c, 2,  'copy : callback triggers on array fetch');
 is($s, 13, 'copy : array fetch is correct');

 $s = exists $a[3];
 is($c, 3, 'copy : callback triggers on array exists');
 ok($s,    'copy : array exists is correct');

 undef @a;
 is($c, 3, 'copy : callback doesn\'t trigger on array undef');
}

SKIP: {
 eval "use Tie::Hash";
 skip 'Tie::Hash required to test copy magic on hashes', 14 if $@;

 tie my %h, 'Tie::StdHash';
 %h = (a => 1, b => 2, c => 3);

 $c = 0;
 my $res = cast %h, $wiz;
 ok($res,  'copy : cast on hash succeeded');
 is($c, 0, 'copy : cast on hash didn\'t triggered the callback');

 $h{b} = 7;
 is($c, 1, 'copy : callback triggers on hash store');

 my $s = $h{c};
 is($c, 2, 'copy : callback triggers on hash fetch');
 is($s, 3, 'copy : hash fetch is correct');

 $s = exists $h{a};
 is($c, 3, 'copy : callback triggers on hash exists');
 ok($s,    'copy : hash exists is correct');

 $s = delete $h{b};
 is($c, 4, 'copy : callback triggers on hash delete');
 is($s, 7, 'copy : hash delete is correct');

 my ($k, $v) = each %h;
 is($c, 5, 'copy : callback triggers on hash each');

 my @k = keys %h;
 is($c, 5, 'copy : callback doesn\'t trigger on hash keys');

 my @v = values %h;
 is(scalar @v, 2, 'copy : two values in the hash');
 is($c, 7,        'copy : callback triggers on hash values');

 undef %h;
 is($c, 7, 'copy : callback doesn\'t trigger on hash undef');
}
