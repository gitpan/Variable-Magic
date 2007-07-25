#!perl -T

use Test::More tests => 12;

use Variable::Magic qw/wizard gensig getsig cast dispell/;

my $sig = gensig;

my $wiz = eval { wizard sig => $sig };
ok(!$@, "wizard creation error ($@)");
ok(defined $wiz, 'wizard is defined');
ok(ref $wiz eq 'SCALAR', 'wizard is a scalar ref');
ok($sig == getsig $wiz, 'wizard signature is correct');

my $a = 0;
my $res = eval { cast $a, $wiz };
ok(!$@, "cast error 1 ($@)");
ok($res, 'cast error 2');

$res = eval { dispell $a, $wiz };
ok(!$@, "dispell from wizard error 1 ($@)");
ok($res, 'dispell from wizard error 2');

$res = eval { cast $a, $wiz };
ok(!$@, "re-cast error 1 ($@)");
ok($res, 're-cast error 2');

$res = eval { dispell $a, $sig };
ok(!$@, "dispell from signature error 1 ($@)");
ok($res, 'dispell from signature error 2');

