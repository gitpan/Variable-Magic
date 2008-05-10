#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use Variable::Magic qw/wizard cast/;

my $wiz = eval { wizard get => sub { undef } };
is($@, '',             'wizard creation doesn\'t croak');
ok(defined $wiz,       'wizard is defined');
is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');

my $n = int rand 1000;
my $a = $n;

my $res = eval { cast $a, $wiz };
is($@, '', 'cast doesn\'t croak');
ok($res,   'cast is valid');

my $x;
eval {
 local $SIG{__WARN__} = sub { die };
 $x = $a
};
is($@, '', 'callback returning undef doesn\'t warn/croak');
is($x, $n, 'callback returning undef fails');
