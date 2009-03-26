#!perl -T

use strict;
use warnings;

use Test::More tests => 48;

use Variable::Magic qw/wizard gensig getsig cast dispell MGf_COPY MGf_DUP MGf_LOCAL VMG_UVAR/;

my $inv_wiz_obj = qr/Invalid\s+wizard\s+object\s+at\s+\Q$0\E/;

my $args = 8;
++$args if MGf_COPY;
++$args if MGf_DUP;
++$args if MGf_LOCAL;
$args += 5 if VMG_UVAR;
for (0 .. 20) {
 next if $_ == $args;
 eval { Variable::Magic::_wizard(('hlagh') x $_) };
 like($@, qr/Wrong\s+number\s+of\s+arguments\s+at\s+\Q$0\E/, '_wizard called directly with a wrong number of arguments croaks');
}

for (0 .. 3) {
 eval { wizard(('dong') x (2 * $_ + 1)) };
 like($@, qr/Wrong\s+number\s+of\s+arguments\s+for\s+&?wizard\(\)\s+at\s+\Q$0\E/, 'wizard called with an odd number of arguments croaks');
}

my $sig = gensig;

my $a = 1;
my $res = eval { cast $a, $sig };
like($@, $inv_wiz_obj, 'cast from wrong sig croaks');
is($res, undef,        'cast from wrong sig doesn\'t return anything');

my $wiz = eval { wizard sig => $sig };
is($@, '',             'wizard doesn\'t croak');
ok(defined $wiz,       'wizard is defined');
is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');
is($sig, getsig $wiz,  'wizard signature is correct');

$res = eval { cast $a, $wiz };
is($@, '', 'cast doesn\'t croak');
ok($res,   'cast is valid');

$res = eval { dispell $a, $wiz };
is($@, '', 'dispell from wizard doesn\'t croak');
ok($res,   'dispell from wizard is valid');

$res = eval { cast $a, $wiz };
is($@, '', 're-cast doesn\'t croak');
ok($res,   're-cast is valid');

$res = eval { dispell $a, gensig };
like($@, $inv_wiz_obj, 're-dispell from wrong sig croaks');
is($res, undef,        're-dispell from wrong sig doesn\'t return anything');

$res = eval { dispell $a, undef };
like($@, $inv_wiz_obj, 're-dispell from undef croaks');
is($res, undef,        're-dispell from undef doesn\'t return anything');

$res = eval { dispell $a, $sig };
is($@, '', 're-dispell from good sig doesn\'t croak');
ok($res,   're-dispell from good sig is valid');

$res = eval { dispell my $b, $wiz };
is($@, '',  'dispell non-magic object doesn\'t croak');
is($res, 0, 'dispell non-magic object returns 0');

$sig = gensig;
{
 my $wiz = wizard sig => $sig;
 my $b = 2;
 my $res = cast $b, $wiz;
}
my $c = 3;
$res = eval { cast $c, $sig };
like($@, $inv_wiz_obj, 'cast from obsolete signature croaks');
is($res, undef,        'cast from obsolete signature returns undef');

$res = eval { cast $c, undef };
like($@, $inv_wiz_obj, 'cast from undef croaks');
is($res, undef,        'cast from undef doesn\'t return anything');
