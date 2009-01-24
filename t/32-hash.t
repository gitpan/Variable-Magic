#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 21 + 7 + 1;

use Variable::Magic qw/cast dispell MGf_COPY VMG_UVAR/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len clear free copy dup local fetch store exists delete/ ],
        'hash';

my %n = map { $_ => int rand 1000 } qw/foo bar baz qux/;
my %h = %n;

check { cast %h, $wiz } { }, 'cast';

my $s = check { $h{foo} } +{ (fetch => 1) x VMG_UVAR },
                       'assign element to';
is $s, $n{foo}, 'hash: assign element to correctly';

for (1 .. 2) {
 $s = check { exists $h{foo} } +{ (exists => 1) x VMG_UVAR }, "exists ($_)";
 ok $s, "hash: exists correctly ($_)";
}

my %b;
check { %b = %h } { }, 'assign to';
is_deeply \%b, \%n, 'hash: assign to correctly';

$s = check { \%h } { }, 'reference';

my @b = check { @h{qw/bar qux/} }
                  +{ (fetch => 2) x VMG_UVAR }, 'slice';
is_deeply \@b, [ @n{qw/bar qux/} ], 'hash: slice correctly';

check { %h = () } { clear => 1 }, 'empty in list context';

check { %h = (a => 1, d => 3); () }
               +{ (store => 2, copy => 2) x VMG_UVAR, clear => 1 },
               'assign from list in void context';

check { %h = map { $_ => 1 } qw/a b d/; }
               +{ (exists => 3, store => 3, copy => 3) x VMG_UVAR, clear => 1 },
               'assign from map in list context';

check { $h{d} = 2; () } +{ (store => 1) x VMG_UVAR },
                    'assign old element';

check { $h{c} = 3; () } +{ (store => 1, copy => 1) x VMG_UVAR },
                    'assign new element';

$s = check { %h } { }, 'buckets';

@b = check { keys %h } { }, 'keys';
is_deeply [ sort @b ], [ qw/a b c d/ ], 'hash: keys correctly';

@b = check { values %h } { }, 'values';
is_deeply [ sort { $a <=> $b } @b ], [ 1, 1, 2, 3 ], 'hash: values correctly';

check { while (my ($k, $v) = each %h) { } } { }, 'each';

check {
 my %b = %n;
 check { cast %b, $wiz } { }, 'cast 2';
} { free => 1 }, 'scope end';

check { undef %h } { clear => 1 }, 'undef';

check { dispell %h, $wiz } { }, 'dispell';
