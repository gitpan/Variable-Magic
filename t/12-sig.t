#!perl -T

use strict;
use warnings;

use Test::More tests => 26;

use Variable::Magic qw/wizard getsig cast dispell SIG_MIN/;

my $sig = 300;

my ($a, $b, $c, $d) = 1 .. 4;

{
 my $wiz = eval { wizard sig => $sig };
 is($@, '',             'wizard creation doesn\'t croak');
 ok(defined $wiz,       'wizard is defined');
 is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');
 is($sig, getsig $wiz,  'wizard signature is correct');

 my $wiz2 = eval { wizard sig => $sig };
 is($@, '',              'wizard retreive doesn\'t croak');
 ok(defined $wiz2,       'retrieved wizard is defined');
 is(ref $wiz2, 'SCALAR', 'retrieved wizard is a scalar ref');
 is($sig, getsig $wiz2,  'retrieved wizard signature is correct');

 my $wiz3 = eval { wizard sig => [ ] };
 like($@, qr/Invalid\s+numeric\s+signature\s+at\s+\Q$0\E/, 'non numeric signature croaks');
 is($wiz3, undef, 'non numeric signature doesn\'t return anything');

 my $a = 1;
 my $res = eval { cast $a, $wiz };
 is($@, '', 'cast from wizard doesn\'t croak');
 ok($res,   'cast from wizard invalid');

 $res = eval { dispell $a, $wiz2 };
 is($@, '', 'dispell from retrieved wizard doesn\'t croak');
 ok($res,   'dispell from retrieved wizard invalid');

 $res = eval { cast $b, $sig };
 is($@, '', 'cast from integer doesn\'t croak');
 ok($res,   'cast from integer invalid');
}

my $res = eval { cast $c, $sig + 0.1 };
is($@, '', 'cast from float doesn\'t croak');
ok($res,   'cast from float invalid');

$res = eval { cast $d, sprintf "%u", $sig };
is($@, '', 'cast from string doesn\'t croak');
ok($res,   'cast from string invalid');

$res = eval { dispell $b, $sig };
is($@, '', 'dispell from integer doesn\'t croak');
ok($res,   'dispell from integer invalid');

$res = eval { dispell $c, $sig + 0.1 };
is($@, '', 'dispell from float doesn\'t croak');
ok($res,   'dispell from float invalid');

$res = eval { dispell $d, sprintf "%u", $sig };
is($@, '', 'dispell from string doesn\'t croak');
ok($res,   'dispell from string invalid');

