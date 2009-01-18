#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast dispell VMG_UVAR/;

if (VMG_UVAR) {
 plan tests => 2 * 9 + 7 + 4 + 1;
} else {
 plan skip_all => 'No nice uvar magic for this perl';
}

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init [ qw/fetch store exists delete/ ], 'uvar';

my %h = (a => 1, b => 2, c => 3);

my $res = check { cast %h, $wiz } { }, 'cast';
ok $res, 'uvar: cast succeeded';

my $x;

check { $x = $h{a} } { fetch => 1 }, 'fetch directly';
is $x, 1, 'uvar: fetch directly correctly';

check { $x = "$h{b}" } { fetch => 1 }, 'fetch by interpolation';
is $x, 2, 'uvar: fetch by interpolation correctly';

check { $h{c} = 4 } { store => 1 }, 'store directly';

check { $x = $h{c} = 5 } { store => 1 }, 'fetch and store';
is $x, 5, 'uvar: fetch and store correctly';

check { $x = exists $h{c} } { exists => 1 }, 'exists';
ok $x, 'uvar: exists correctly';

check { $x = delete $h{c} } { delete => 1 }, 'delete existing key';
is $x, 5, 'uvar: delete existing key correctly';

check { $x = delete $h{z} } { delete => 1 }, 'delete non-existing key';
ok !defined $x, 'uvar: delete non-existing key correctly';

my $wiz2 = wizard 'fetch'  => sub { 0 };
my %h2 = (a => 37, b => 2, c => 3);
cast %h2, $wiz2;

eval {
 local $SIG{__WARN__} = sub { die };
 $x = $h2{a};
};
is $@, '', 'uvar: fetch with incomplete magic';
is $x, 37, 'uvar: fetch with incomplete magic correctly';

eval {
 local $SIG{__WARN__} = sub { die };
 $h2{a} = 73;
};
is $@, '',     'uvar: store with incomplete magic';
is $h2{a}, 73, 'uvar: store with incomplete magic correctly';
