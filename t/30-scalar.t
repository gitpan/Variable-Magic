#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 14 + 2 + 1;

use Variable::Magic qw/cast dispell/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len clear free copy dup local fetch store exists delete/ ],
        'scalar';

my $n = int rand 1000;
my $a = $n;

check { cast $a, $wiz } { }, 'cast';

my $b = check { $a } { get => 1 }, 'assign to';
is $b, $n, 'scalar: assign to correctly';

$b = check { "X${a}Y" } { get => 1 }, 'interpolate';
is $b, "X${n}Y", 'scalar: interpolate correctly';

$b = check { \$a } { }, 'reference';

check { $a = 123; () } { set => 1 }, 'assign to';

check { ++$a; () } { get => 1, set => 1 }, 'increment';

check { --$a; () } { get => 1, set => 1 }, 'decrement';

check { $a *= 1.5; () } { get => 1, set => 1 }, 'multiply in place';

check { $a /= 1.5; () } { get => 1, set => 1 }, 'divide in place';

check {
 my $b = $n;
 check { cast $b, $wiz } { }, 'cast 2';
} { free => 1 }, 'scope end';

check { undef $a } { set => 1 }, 'undef';

check { dispell $a, $wiz } { }, 'dispell';
