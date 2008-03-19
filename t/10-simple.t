#!perl -T

use strict;
use warnings;

use Test::More tests => 46;

use Variable::Magic qw/wizard gensig getsig cast dispell MGf_COPY MGf_DUP MGf_LOCAL VMG_UVAR/;

my $args = 7;
++$args if MGf_COPY;
++$args if MGf_DUP;
++$args if MGf_LOCAL;
$args += 4 if VMG_UVAR;
for (0 .. 20) {
 next if $_ == $args;
 eval { Variable::Magic::_wizard(('hlagh') x $_) };
 ok($@, "_wizard called directly with a wrong number of arguments croaks ($@)");
}

for (0 .. 3) {
 eval { wizard(('dong') x (2 * $_ + 1)) };
 ok($@, "wizard called with an odd number of arguments croaks ($@)");
}

my $sig = gensig;

my $wiz = eval { wizard sig => $sig };
ok(!$@,                "wizard doesn't croak ($@)");
ok(defined $wiz,       'wizard is defined');
is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');
is($sig, getsig $wiz,  'wizard signature is correct');

my $a = 1;
my $res = eval { cast $a, $wiz };
ok(!$@,  "cast doesn't croak ($@)");
ok($res, 'cast is valid');

$res = eval { dispell $a, $wiz };
ok(!$@,  "dispell from wizard doesn't croak ($@)");
ok($res, 'dispell from wizard is valid');

$res = eval { cast $a, $wiz };
ok(!$@,  "re-cast doesn't croak ($@)");
ok($res, 're-cast is valid');

$res = eval { dispell $a, gensig };
ok(!$@,            "re-dispell from wrong sig doesn't croak ($@)");
ok(!defined($res), 're-dispell from wrong sig returns undef');

$res = eval { dispell $a, undef };
ok($@,             "re-dispell from undef croaks ($@)");
ok(!defined($res), 're-dispell from undef returns undef');

$res = eval { dispell $a, $sig };
ok(!$@,  "re-dispell from good sig doesn't croak ($@)");
ok($res, 're-dispell from good sig is valid');

$res = eval { dispell my $b, $wiz };
ok(!$@, "dispell non-magic object doesn't croak ($@)");
is($res, 0, 'dispell non-magic object returns 0');

$sig = gensig;
{
 my $wiz = wizard sig => $sig;
 my $b = 2;
 my $res = cast $b, $wiz;
}
my $c = 3;
$res = eval { cast $c, $sig };
ok(!$@, "cast from obsolete signature doesn't croak ($@)");
ok(!defined($res), 'cast from obsolete signature returns undef');

$res = eval { cast $c, undef };
ok($@, "cast from undef croaks ($@)");
ok(!defined($res), 'cast from undef returns undef');
