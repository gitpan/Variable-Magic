#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
 local $@;
 if (eval "use Symbol qw<gensym>; 1") {
  plan tests => 2 * 12 + 1;
  defined and diag "Using Symbol $_" for $Symbol::VERSION;
 } else {
  plan skip_all => "Symbol::gensym required for testing magic for globs";
 }
}

use Variable::Magic qw<cast dispell VMG_COMPAT_GLOB_GET>;

my %get = VMG_COMPAT_GLOB_GET ? (get => 1) : ();

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init_watcher
        [ qw<get set len clear free copy dup local fetch store exists delete> ],
        'glob';

local *a = gensym();

watch { cast *a, $wiz } +{ }, 'cast';

watch { local *b = *a } +{ %get }, 'assign to';

watch { *a = \1 }          +{ %get, set => 1 }, 'assign scalar slot';
watch { *a = [ qw<x y> ] } +{ %get, set => 1 }, 'assign array slot';
watch { *a = { u => 1 } }  +{ %get, set => 1 }, 'assign hash slot';
watch { *a = sub { } }     +{ %get, set => 1 }, 'assign code slot';

watch { *a = gensym() }    +{ %get, set => 1 }, 'assign glob';

watch {
 local *b = gensym();
 watch { cast *b, $wiz } +{ }, 'cast 2';
} +{ }, 'scope end';

%get = () if $] >= 5.013007;

watch { undef *a } +{ %get }, 'undef';

watch { dispell *a, $wiz } +{ %get }, 'dispell';
