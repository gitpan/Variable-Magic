#!perl -T

use strict;
use warnings;

use Test::More tests => 24;

use Variable::Magic qw/wizard getsig cast dispell SIG_MIN/;

my $sig = 300;

my ($a, $b, $c, $d) = 1 .. 4;

{
 my $wiz = eval { wizard sig => $sig };
 ok(!$@, "wizard creation doesn't croak ($@)");
 ok(defined $wiz, 'wizard is defined');
 is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');
 is($sig, getsig $wiz, 'wizard signature is correct');

 my $wiz2 = eval { wizard sig => $sig };
 ok(!$@, "wizard retreive doesn't croak ($@)");
 ok(defined $wiz2, 'retrieved wizard is defined');
 is(ref $wiz2, 'SCALAR', 'retrieved wizard is a scalar ref');
 is($sig, getsig $wiz2, 'retrieved wizard signature is correct');

 my $a = 1;
 my $res = eval { cast $a, $wiz };
 ok(!$@, "cast from wizard croaks ($@)");
 ok($res, 'cast from wizard invalid');

 $res = eval { dispell $a, $wiz2 };
 ok(!$@, "dispell from retrieved wizard croaks ($@)");
 ok($res, 'dispell from retrieved wizard invalid');

 $res = eval { cast $b, $sig };
 ok(!$@, "cast from integer croaks ($@)");
 ok($res, 'cast from integer invalid');
}

my $res = eval { cast $c, $sig + 0.1 };
ok(!$@, "cast from float croaks ($@)");
ok($res, 'cast from float invalid');

$res = eval { cast $d, sprintf "%u", $sig };
ok(!$@, "cast from string croaks ($@)");
ok($res, 'cast from string invalid');

$res = eval { dispell $b, $sig };
ok(!$@, "dispell from integer croaks ($@)");
ok($res, 'dispell from integer invalid');

$res = eval { dispell $c, $sig + 0.1 };
ok(!$@, "dispell from float croaks ($@)");
ok($res, 'dispell from float invalid');

$res = eval { dispell $d, sprintf "%u", $sig };
ok(!$@, "dispell from string croaks ($@)");
ok($res, 'dispell from string invalid');

