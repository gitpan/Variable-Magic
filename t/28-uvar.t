#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast dispell VMG_UVAR/;

if (VMG_UVAR) {
 plan tests => 20;
} else {
 plan skip_all => 'No nice uvar magic for this perl';
}

my @c = (0) x 4;
my @x = (0) x 4;

sub check {
 for (0 .. 3) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
}

my $wiz = wizard 'fetch'  => sub { ++$c[0] },
                 'store'  => sub { ++$c[1] },
                 'exists' => sub { ++$c[2] },
                 'delete' => sub { ++$c[3] };
ok(check(), 'uvar : create wizard');

my %h = (a => 1, b => 2, c => 3);
my $res = cast %h, $wiz;
ok($res,    'uvar : cast succeeded');
ok(check(), 'uvar : cast didn\'t triggered the callback');

my $x = $h{a};
++$x[0];
ok(check(), 'uvar : fetch directly');
ok($x,      'uvar : fetch directly correctly');

$x = "$h{b}";
++$x[0];
ok(check(), 'uvar : fetch by interpolation');
ok($x == 2, 'uvar : fetch by interpolation correctly');

$h{c} = 4;
++$x[1];
ok(check(), 'uvar : store directly');

$x = $h{c} = 5;
++$x[1];
ok(check(), 'uvar : fetch and store');
ok($x == 5, 'uvar : fetch and store correctly');

$x = exists $h{c};
++$x[2];
ok(check(), 'uvar : exists');
ok($x,      'uvar : exists correctly');

$x = delete $h{c};
++$x[3];
ok(check(), 'uvar : delete existing key');
ok($x == 5, 'uvar : delete existing key correctly');

$x = delete $h{z};
++$x[3];
ok(check(),     'uvar : delete non-existing key');
ok(!defined $x, 'uvar : delete non-existing key correctly');

my $wiz2 = wizard 'fetch'  => sub { 0 };
my %h2 = (a => 37, b => 2, c => 3);
cast %h2, $wiz2;

eval {
 local $SIG{__WARN__} = sub { die };
 $x = $h2{a};
};
ok(!$@,      'uvar : fetch with incomplete magic');
ok($x == 37, 'uvar : fetch with incomplete magic correctly');

eval {
 local $SIG{__WARN__} = sub { die };
 $h2{a} = 73;
};
ok(!$@,         'uvar : store with incomplete magic');
ok($h2{a} == 73, 'uvar : store with incomplete magic correctly');
