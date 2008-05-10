#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast dispell VMG_UVAR/;

if (!VMG_UVAR) {
 plan skip_all => 'No nice uvar magic for this perl';
}

eval "use Hash::Util::FieldHash";
if ($@) {
 plan skip_all => 'Hash::Util::FieldHash required for testing uvar interaction';
} else {
 plan tests => 12;
 my $v = $Hash::Util::FieldHash::VERSION;
 diag "Using Hash::Util::FieldHash $v" if defined $v;
}

Hash::Util::FieldHash::fieldhash(\my %h);

my $obj = { };
bless $obj, 'Variable::Magic::Test::Mock';
$h{$obj} = 5;

my ($w, $c) = (undef, 0);

eval { $w = wizard fetch => sub { ++$c }, store => sub { --$c } };
is($@, '',           'wizard with uvar doesn\'t croak');
ok(defined $w,       'wizard with uvar is defined');
is(ref $w, 'SCALAR', 'wizard with uvar is a scalar ref');

my $res = eval { cast %h, $w };
is($@, '', 'cast uvar magic on fieldhash doesn\'t croak');
ok($res,   'cast uvar magic on fieldhash is valid');

my $s = $h{$obj};
is($s, 5, 'fetch magic on fieldhash doesn\'t clobber');
is($c, 1, 'fetch magic on fieldhash');

$h{$obj} = 7;
is($c, 0,       'store magic on fieldhash');
is($h{$obj}, 7, 'store magic on fieldhash doesn\'t clobber'); # $c == 1

$res = eval { dispell %h, $w };
is($@, '', 'dispell uvar magic on fieldhash doesn\'t croak');
ok($res,   'dispell uvar magic on fieldhash is valid');

$h{$obj} = 11;
$s = $h{$obj};
is($s, 11, 'store/fetch on fieldhash after dispell still ok');
