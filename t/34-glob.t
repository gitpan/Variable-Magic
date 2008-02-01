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

my @c = (0) x 12;
my @x = (0) x 12;

sub check {
 for (0 .. 11) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
}

my $i = -1;
my $wiz = wizard get   => sub { ++$c[0] },
                 set   => sub { ++$c[1] },
                 len   => sub { ++$c[2] },
                 clear => sub { ++$c[3] },
                 free  => sub { ++$c[4] },
                 copy  => sub { ++$c[5] },
                 dup   => sub { ++$c[6] },
                 local => sub { ++$c[7] },
                 fetch => sub { ++$c[8] },
                 store => sub { ++$c[9] },
                 'exists' => sub { ++$c[10] },
                 'delete' => sub { ++$c[11] };
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
