#!perl -T

use strict;
use warnings;

use Test::More tests => 14;

use Variable::Magic qw/wizard gensig getsig cast dispell/;

my $sig = gensig;

my $wiz = eval { wizard sig => $sig };
ok(!$@, "wizard creation error ($@)");
ok(defined $wiz, 'wizard is defined');
ok(ref $wiz eq 'SCALAR', 'wizard is a scalar ref');
ok($sig == getsig $wiz, 'wizard signature is correct');

my $a = 1;
my $res = eval { cast $a, $wiz };
ok(!$@, "cast croaks ($@)");
ok($res, 'cast invalid');

$res = eval { dispell $a, $wiz };
ok(!$@, "dispell from wizard croaks ($@)");
ok($res, 'dispell from wizard invalid');

$res = eval { cast $a, $wiz };
ok(!$@, "re-cast croaks ($@)");
ok($res, 're-cast invalid');

$res = eval { dispell $a, $wiz };
ok(!$@, "re-dispell croaks ($@)");
ok($res, 're-dispell invalid');

$sig = gensig;
{
 my $wiz = wizard sig => $sig;
 my $b = 2;
 my $res = cast $b, $wiz;
}
my $c = 3;
$res = eval { cast $c, $sig };
ok(!$@, "cast from obsolete signature croaks ($@)");
ok(!defined($res), 'cast from obsolete signature returns undef');
