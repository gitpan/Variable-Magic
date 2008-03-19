#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard clear => sub { ++$c };
is($c, 0, 'clear : create wizard');

my @a = qw/a b c/;

cast @a, $wiz;
is($c, 0, 'clear : cast array');

@a = ();
is($c, 1,          'clear : clear array');
ok(!defined $a[0], 'clear : clear array correctly');

my %h = (foo => 1, bar => 2);

cast %h, $wiz;
is($c, 1, 'clear : cast hash');

%h = ();
is($c, 2,      'clear : clear hash');
ok(!(keys %h), 'clear : clear hash correctly');
