#!perl -T

use strict;
use warnings;

use Config qw/%Config/;

BEGIN {
 if (!$Config{useithreads}) {
  require Test::More;
  Test::More->import;
  plan(skip_all => 'This perl wasn\'t built to support threads');
 }
}

use threads; # Before Test::More
use threads::shared;

use Test::More;

use Variable::Magic qw/wizard cast dispell getdata VMG_THREADSAFE/;

if (VMG_THREADSAFE) {
 plan tests => 2 * (2 * 16 + 1) + 2 * (2 * 11 + 1);
} else {
 plan skip_all => 'This Variable::Magic isn\'t thread safe';
}

my $destroyed : shared = 0;
my $sig = undef;

sub try {
 my ($dispell) = @_;
 my $tid = threads->tid();
 my $c   = 0;
 my $wiz = eval {
  wizard get  => sub { ++$c },
         data => sub { $_[1] + $tid },
         free => sub { ++$destroyed },
         sig  => $sig;
 };
 is($@,     '',    "wizard in thread $tid doesn't croak");
 isnt($wiz, undef, "wizard in thread $tid is defined");
 is($c,     0,     "wizard in thread $tid doesn't trigger magic");
 my $a = 3;
 my $res = eval { cast $a, $wiz, sub { 5 }->() };
 is($@, '', "cast in thread $tid doesn't croak");
 is($c, 0,  "cast in thread $tid doesn't trigger magic");
 my $b;
 eval { $b = $a };
 is($@, '', "get in thread $tid doesn't croak");
 is($b, 3,  "get in thread $tid returns the right thing");
 is($c, 1,  "get in thread $tid triggers magic");
 my $d = eval { getdata $a, $wiz };
 is($@, '',       "getdata in thread $tid doesn't croak");
 is($d, 5 + $tid, "getdata in thread $tid returns the right thing");
 is($c, 1,        "getdata in thread $tid doesn't trigger magic");
 if ($dispell) {
  $res = eval { dispell $a, $wiz };
  is($@, '', "dispell in thread $tid doesn't croak");
  is($c, 1,  "dispell in thread $tid doesn't trigger magic");
  undef $b;
  eval { $b = $a };
  is($@, '', "get in thread $tid after dispell doesn't croak");
  is($b, 3,  "get in thread $tid after dispell returns the right thing");
  is($c, 1,  "get in thread $tid after dispell doesn't trigger magic");
 }
 return; # Ugly if not here
}

for my $dispell (1, 0) {
 $destroyed = 0;
 $sig = undef;

 my @t = map { threads->create(\&try, $dispell) } 1 .. 2;
 $t[0]->join;
 $t[1]->join;

 is($destroyed, (1 - $dispell) * 2, 'destructors');

 $destroyed = 0;
 $sig = Variable::Magic::gensig();

 @t = map { threads->create(\&try, $dispell) } 1 .. 2;
 $t[0]->join;
 $t[1]->join;

 is($destroyed, (1 - $dispell) * 2, 'destructors');
}
