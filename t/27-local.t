#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/cast MGf_LOCAL/;

if (MGf_LOCAL) {
 plan tests => 2 * 3 + 1 + 1;
} else {
 plan skip_all => 'No local magic for this perl';
}

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init 'local', 'local';

our $a = int rand 1000;

my $res = check { cast $a, $wiz } { }, 'cast';
ok $res, 'local: cast succeeded';

check { local $a } { local => 1 }, 'localized';
