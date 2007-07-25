#!perl -T

use Test::More tests => 7;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard clear => sub { ++$c };
ok($c == 0, 'clear : create wizard');

my @a = qw/a b c/;

cast @a, $wiz;
ok($c == 0, 'clear : cast array');

@a = ();
ok($c == 1, 'clear : clear array');
ok(!defined $a[0], 'clear : clear array correctly');

my %h = (foo => 1, bar => 2);

cast %h, $wiz;
ok($c == 1, 'clear : cast hash');

%h = ();
ok($c == 2, 'clear : clear hash');
ok(!(keys %h), 'clear : clear hash correctly');
