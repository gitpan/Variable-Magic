#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 25 + 9 + 1;

use Variable::Magic qw/cast dispell VMG_COMPAT_ARRAY_PUSH_NOLEN VMG_COMPAT_ARRAY_UNSHIFT_NOLEN_VOID VMG_COMPAT_ARRAY_UNDEF_CLEAR/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len clear free copy dup local fetch store exists delete/ ],
        'array';

my @n = map { int rand 1000 } 1 .. 5;
my @a = @n;

check { cast @a, $wiz } { }, 'cast';

my $b;
check { $b = $a[2] } { }, 'assign element to';
is $b, $n[2], 'array: assign element to correctly';

my @b;
check { @b = @a } { len => 1 }, 'assign to';
is_deeply \@b, \@n, 'array: assign to correctly';

check { $b = "X@{a}Y" } { len => 1 }, 'interpolate';
is $b, "X@{n}Y", 'array: interpolate correctly';

check { $b = \@a } { }, 'reference';

check { @b = @a[2 .. 4] } { }, 'slice';
is_deeply \@b, [ @n[2 .. 4] ], 'array: slice correctly';

check { @a = qw/a b d/ } { set => 3, clear => 1 }, 'assign';

check { $a[2] = 'c' } { }, 'assign old element';

check { $a[3] = 'd' } { set => 1 }, 'assign new element';

check { push @a, 'x'; () }
          { set => 1, (len => 1) x !VMG_COMPAT_ARRAY_PUSH_NOLEN },'push (void)';
check { $b = push @a, 'y' }
       { set => 1, (len => 1) x !VMG_COMPAT_ARRAY_PUSH_NOLEN }, 'push (scalar)';

check { $b = pop @a } { set => 1, len => 1 }, 'pop';
is $b, 'y', 'array: pop correctly';

check { unshift @a, 'z'; () }
                { set => 1, (len => 1) x !VMG_COMPAT_ARRAY_UNSHIFT_NOLEN_VOID },
                'unshift (void)';

check { $b = unshift @a, 't' } { set => 1, len => 1 }, 'unshift (scalar)';

check { $b = shift @a } { set => 1, len => 1 }, 'shift';
is $b, 't', 'array: shift correctly';

check { $b = @a } { len => 1 }, 'length @';
is $b, 6, 'array: length @ correctly';

check { $b = $#a } { len => 1 }, 'length $#';
is $b, 5, 'array: length $# correctly';

check { my $i; @a = map ++$i, @a; () } { set => 6, len => 1, clear => 1}, 'map';

check { @b = grep { $_ >= 4 } @a } { len => 1 }, 'grep';
is_deeply \@b, [ 4 .. 6 ], 'array: grep correctly';

check { 1 for @a } { len => 6 + 1 }, 'for';

check {
 my @b = @n;
 check { cast @b, $wiz } { }, 'cast 2';
} { free => 1 }, 'scope end';

check { undef @a } +{ (clear => 1) x VMG_COMPAT_ARRAY_UNDEF_CLEAR }, 'undef';

check { dispell @a, $wiz } { }, 'dispell';
