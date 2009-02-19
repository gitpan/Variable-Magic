#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 12 + 11 + 1;

use Variable::Magic qw/cast dispell/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len clear free copy dup local fetch store exists delete/ ],
        'code';

my $x = 0;
sub hlagh { ++$x };

check { cast &hlagh, $wiz } { }, 'cast';
is $x, 0, 'code: cast didn\'t called code';

check { hlagh() } { }, 'call without arguments';
is $x, 1, 'code: call without arguments succeeded';

check { hlagh(1, 2, 3) } { }, 'call with arguments';
is $x, 2, 'code: call with arguments succeeded';

check { undef *hlagh } { free => 1 }, 'undef symbol table entry';
is $x, 2, 'code: undef symbol table entry didn\'t call code';

my $y = 0;
check { *hlagh = sub { ++$y } } { }, 'redefining sub';

check { cast &hlagh, $wiz } { }, 're-cast';
is $y, 0, 'code: re-cast didn\'t called code';

my ($r) = check { \&hlagh } { }, 'reference';
is $y, 0, 'code: reference didn\'t called code';

check { $r->() } { }, 'call reference';
is $y, 1, 'code: call reference succeeded';
is $x, 2, 'code: call reference didn\'t called the previous code';

my $z = 0;
check {
 no warnings 'redefine';
 *hlagh = sub { ++$z }
} { }, 'redefining sub 2';

check { hlagh() } { }, 'call without arguments 2';
is $z, 1, 'code: call without arguments 2 succeeded';
is $y, 1, 'code: call without arguments 2 didn\'t called the previous code';

check { dispell &hlagh, $wiz } { }, 'dispell';
is $z, 1, 'code: dispell didn\'t called code';

$Variable::Magic::TestWatcher::mg_end = { free => 1 };
