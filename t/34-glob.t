#!perl -T

use strict;
use warnings;

use Test::More;

eval "use Symbol qw/gensym/";
if ($@) {
 plan skip_all => "Symbol::gensym required for testing magic for globs";
} else {
 plan tests => 7;
}

use Variable::Magic qw/wizard cast dispell/;

my @c = (0) x 5;
my @x = (0) x 5;

sub check {
 for (0 .. 4) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
}

my $i = -1;
my $wiz = wizard get   => sub { ++$c[0] },
                 set   => sub { ++$c[1] },
                 len   => sub { ++$c[2] },
                 clear => sub { ++$c[3] },
                 free  => sub { ++$c[4] };
ok(check(), 'glob : create wizard');

local *a = gensym();

cast *a, $wiz;
ok(check(), 'glob : cast');

local *b = *a;
ok(check(), 'glob : assign to');

*a = gensym();
++$x[1];
ok(check(), 'glob : assign');

{
 local *b = gensym();
 cast *b, $wiz;
}
ok(check(), 'glob : scope end');

undef *a;
ok(check(), 'glob : undef');

dispell *a, $wiz;
ok(check(), 'glob : dispell');
