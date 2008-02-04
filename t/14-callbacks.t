#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use Variable::Magic qw/wizard cast/;

my $wiz = eval { wizard get => sub { undef } };
ok(!$@, "wizard creation error ($@)");
ok(defined $wiz, 'wizard is defined');
ok(ref $wiz eq 'SCALAR', 'wizard is a scalar ref');

my $n = int rand 1000;
my $a = $n;

my $res = eval { cast $a, $wiz };
ok(!$@, "cast croaks ($@)");
ok($res, 'cast invalid');

my $x;
eval {
 local $SIG{__WARN__} = sub { die };
 $x = $a
};
ok(!$@, 'callback returning undef croaks');
ok(defined($x) && ($x == $n), 'callback returning undef fails');
