#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 5 + 1;

use Variable::Magic qw/cast/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init 'free', 'free';

my $n = int rand 1000;

check {
 my $a = $n;
 check { cast $a, $wiz } { }, 'cast';
} { free => 1 }, 'deletion at the end of the scope';

my $a = $n;
check { cast $a, $wiz } { }, 'cast 2';
check { undef $a } { }, 'explicit deletion with undef()';

$Variable::Magic::TestWatcher::mg_end = { free => 1 };
