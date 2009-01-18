#!perl -T

use strict;
use warnings;

use Test::More;

eval "use Symbol qw/gensym/";
if ($@) {
 plan skip_all => "Symbol::gensym required for testing magic for globs";
} else {
 plan tests => 2 * 8 + 1;
 diag "Using Symbol $Symbol::VERSION" if defined $Symbol::VERSION;
}

use Variable::Magic qw/cast dispell/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len clear free copy dup local fetch store exists delete/ ],
        'glob';

local *a = gensym();

check { cast *a, $wiz } { }, 'cast';

check { local *b = *a } { }, 'assign to';

check { *a = gensym() } { set => 1 }, 'assign';

check {
 local *b = gensym();
 check { cast *b, $wiz } { }, 'cast 2';
} { }, 'scope end';

check { undef *a } { }, 'undef';

check { dispell *a, $wiz } { }, 'dispell';
