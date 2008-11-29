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

use Variable::Magic qw/wizard cast dispell getdata getsig VMG_THREADSAFE/;

if (VMG_THREADSAFE) {
 plan tests => 3 + 2 * (2 * 8 + 2) + 2 * (2 * 5 + 2);
 my $v = $threads::VERSION;
 diag "Using threads $v" if defined $v;
 $v = $threads::shared::VERSION;
 diag "Using threads::shared $v" if defined $v;
} else {
 plan skip_all => 'This Variable::Magic isn\'t thread safe';
}

my $destroyed : shared = 0;
my $c         : shared = 0;
my $wiz = eval {
 wizard get  => sub { ++$c },
        data => sub { $_[1] + threads->tid() },
        free => sub { ++$destroyed }
};
is($@,     '',    "wizard in main thread doesn't croak");
isnt($wiz, undef, "wizard in main thread is defined");
is($c,     0,     "wizard in main thread doesn't trigger magic");

my $sig;

sub try {
 my ($dispell) = @_;
 my $tid = threads->tid();
 my $a   = 3;
 my $res = eval { cast $a, $sig, sub { 5 }->() };
 is($@, '', "cast in thread $tid doesn't croak");
 my $b;
 eval { $b = $a };
 is($@, '', "get in thread $tid doesn't croak");
 is($b, 3,  "get in thread $tid returns the right thing");
 my $d = eval { getdata $a, $sig };
 is($@, '',       "getdata in thread $tid doesn't croak");
 is($d, 5 + $tid, "getdata in thread $tid returns the right thing");
 if ($dispell) {
  $res = eval { dispell $a, $sig };
  is($@, '', "dispell in thread $tid doesn't croak");
  undef $b;
  eval { $b = $a };
  is($@, '', "get in thread $tid after dispell doesn't croak");
  is($b, 3,  "get in thread $tid after dispell returns the right thing");
 }
 return; # Ugly if not here
}

for my $dispell (1, 0) {
 $c = 0;
 $destroyed = 0;
 $sig = $wiz;

 my @t = map { threads->create(\&try, $dispell) } 1 .. 2;
 $t[0]->join;
 $t[1]->join;

 is($c, 2, "get triggered twice");
 is($destroyed, (1 - $dispell) * 2, 'destructors');

 $c = 0;
 $destroyed = 0;
 $sig = getsig $wiz;

 @t = map { threads->create(\&try, $dispell) } 1 .. 2;
 $t[0]->join;
 $t[1]->join;

 is($c, 2, "get triggered twice");
 is($destroyed, (1 - $dispell) * 2, 'destructors');
}
