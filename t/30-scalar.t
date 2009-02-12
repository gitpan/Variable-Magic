#!perl -T

use strict;
use warnings;

use Test::More tests => (2 * 14 + 2) + 2 * (2 * 8 + 4) + 1;

use Variable::Magic qw/cast dispell/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len clear free copy dup local fetch store exists delete/ ],
        'scalar';

my $n = int rand 1000;
my $a = $n;

check { cast $a, $wiz } { }, 'cast';

my $b;
# $b has to be set inside the block for the test to pass on 5.8.3 and lower
check { $b = $a } { get => 1 }, 'assign to';
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

# Array element

my @a = (7, 8, 9);

check { cast $a[1], $wiz } { }, 'array element: cast';

check { $a[1] = 6; () } { set => 1 }, 'array element: set';

$b = check { $a[1] } { get => 1 }, 'array element: get';
is $b, 6, 'scalar: array element: get correctly';

check { $a[0] = 5 } { }, 'array element: set other';

$b = check { $a[2] } { }, 'array element: get other';
is $b, 9, 'scalar: array element: get other correctly';

$b = check { exists $a[1] } { }, 'array element: exists';
is $b, 1, 'scalar: array element: exists correctly';

# $b has to be set inside the block for the test to pass on 5.8.3 and lower
check { $b = delete $a[1] } { get => 1, free => ($] > 5.008005 ? 1 : 0) }, 'array element: delete';
is $b, 6, 'scalar: array element: delete correctly';

check { $a[1] = 4 } { }, 'array element: set after delete';

# Hash element

my %h = (a => 7, b => 8);

check { cast $h{b}, $wiz } { }, 'hash element: cast';

check { $h{b} = 6; () } { set => 1 }, 'hash element: set';

$b = check { $h{b} } { get => 1 }, 'hash element: get';
is $b, 6, 'scalar: hash element: get correctly';

check { $h{a} = 5 } { }, 'hash element: set other';

$b = check { $h{a} } { }, 'hash element: get other';
is $b, 5, 'scalar: hash element: get other correctly';

$b = check { exists $h{b} } { }, 'hash element: exists';
is $b, 1, 'scalar: hash element: exists correctly';

$b = check { delete $h{b} } { get => 1, free => 1 }, 'hash element: delete';
is $b, 6, 'scalar: hash element: delete correctly';

check { $h{b} = 4 } { }, 'hash element: set after delete';

