#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 5 + 2 + 1;

use Variable::Magic qw/cast/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init 'clear', 'clear';

my @a = qw/a b c/;

check { cast @a, $wiz } { }, 'cast array';

check { @a = () } { clear => 1 }, 'clear array';
is_deeply \@a, [ ], 'clear: clear array correctly';

my %h = (foo => 1, bar => 2);

check { cast %h, $wiz } { }, 'cast hash';

check { %h = () } { clear => 1 }, 'clear hash';
is_deeply \%h, { }, 'clear: clear hash correctly';
