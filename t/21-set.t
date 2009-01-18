#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 5 + 3 + 1;

use Variable::Magic qw/cast/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init 'set', 'set';

my $a = 0;

check { cast $a, $wiz } { }, 'cast';

my $n = int rand 1000;

check { $a = $n } { set => 1 }, 'assign';
is $a, $n, 'set: assign correctly';

check { ++$a } { set => 1 }, 'increment';
is $a, $n + 1, 'set: increment correctly';

check { --$a } { set => 1 }, 'decrement';
is $a, $n, 'set: decrement correctly';
