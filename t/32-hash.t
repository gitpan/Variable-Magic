#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 18 + 5 + 1;

use Variable::Magic qw/cast dispell MGf_COPY VMG_UVAR/;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init
        [ qw/get set len free dup local fetch store exists delete/ ], # clear copy
        'hash';

my %n = map { $_ => int rand 1000 } qw/foo bar baz qux/;
my %h = %n;

check { cast %h, $wiz } { }, 'cast';

my $s;
check { $s = $h{foo} } +{ (fetch => 1) x VMG_UVAR },
                       # (copy => 1) x MGf_COPY # if clear magic
                       'assign element to';
is $s, $n{foo}, 'hash: assign element to correctly';

my %b;
check { %b = %h } { }, 'assign to';
is_deeply \%b, \%n, 'hash: assign to correctly';

check { $s = \%h } { }, 'reference';

my @b;
check { @b = @h{qw/bar qux/} }
                  +{ (fetch => 2) x VMG_UVAR }, 'slice';
                  # (copy => 2) x MGf_COPY # if clear magic
is_deeply \@b, [ @n{qw/bar qux/} ], 'hash: slice correctly';

check { %h = (a => 1, d => 3); () }
               +{ (store => 2) x VMG_UVAR },
               # clear => 1, (copy => 2) x VMG_UVAR
               'assign from list in void context';

check { %h = map { $_ => 1 } qw/a b d/; }
               +{ (exists => 3, store => 3) x VMG_UVAR },
               # clear => 1, (copy => 3) x VMG_UVAR
               'assign from map in list context';

check { $h{d} = 2; () } +{ (store => 1) x VMG_UVAR },
                    'assign old element';

check { $h{c} = 3; () } +{ (store => 1) x VMG_UVAR },
                    # (copy => 1) x VMG_UVAR # maybe also if clear magic
                    'assign new element';

check { $s = %h } { }, 'buckets';

check { @b = keys %h } { }, 'keys';
is_deeply [ sort @b ], [ qw/a b c d/ ], 'hash: keys correctly';

check { @b = values %h } { }, 'values';
is_deeply [ sort { $a <=> $b } @b ], [ 1, 1, 2, 3 ], 'hash: values correctly';

check { while (my ($k, $v) = each %h) { } } { }, 'each';

check {
 my %b = %n;
 check { cast %b, $wiz } { }, 'cast 2';
} { free => 1 }, 'scope end';

check { undef %h } { }, 'undef'; # clear => 1

check { dispell %h, $wiz } { }, 'dispell';
