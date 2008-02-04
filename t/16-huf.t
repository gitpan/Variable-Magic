#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast dispell VMG_UVAR/;

if (!VMG_UVAR) {
 plan skip_all => 'No nice uvar magic for this perl';
}

eval "use Hash::Util::FieldHash qw/fieldhash/";
if ($@) {
 plan skip_all => 'Hash::Util::FieldHash required for testing uvar interaction';
} else {
 plan tests => 12;
}

fieldhash(my %h);

bless \(my $obj = {}), 'Variable::Magic::Test::Mock';
$h{$obj} = 5;

my ($w, $c) = (undef, 0);

eval { $w = wizard fetch => sub { ++$c }, store => sub { --$c } };
ok(!$@, "wizard with uvar creation error ($@)");
ok(defined $w, 'wizard with uvar is defined');
ok(ref($w) eq 'SCALAR', 'wizard with uvar is a scalar ref');

my $res = eval { cast %h, $w };
ok(!$@, "cast uvar magic on fieldhash croaks ($@)");
ok($res, 'cast uvar magic on fieldhash invalid');

my $s = $h{$obj};
ok($s == 5, 'fetch magic on fieldhash doesn\'t clobber');
ok($c == 1, 'fetch magic on fieldhash');

$h{$obj} = 7;
ok($c == 0, 'store magic on fieldhash');
ok($h{$obj} == 7, 'store magic on fieldhash doesn\'t clobber'); # $c == 1

$res = eval { dispell %h, $w };
ok(!$@, "dispell uvar magic on fieldhash croaks ($@)");
ok($res, 'dispell uvar magic on fieldhash invalid');

$h{$obj} = 11;
$s = $h{$obj};
ok($s == 11, 'store/fetch on fieldhash after dispell still ok');
