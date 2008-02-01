#!perl -T

use strict;
use warnings;

use Test::More tests => 33 + 24 + 12;

use Variable::Magic qw/wizard cast dispell VMG_UVAR/;

my $n = 3;
my @w;
my @c = (0) x $n;

sub multi {
 my ($cb, $tests) = @_;
 for (my $i = 0; $i < $n; ++$i) {
  my $res = eval { $cb->($i) };
  $tests->($i, $res, $@);
 }
}

eval { $w[0] = wizard get => sub { ++$c[0] }, set => sub { --$c[0] } };
ok(!$@, "wizard 0 creation error ($@)");
eval { $w[1] = wizard get => sub { ++$c[1] }, set => sub { --$c[1] } };
ok(!$@, "wizard 1 creation error ($@)");
eval { $w[2] = wizard get => sub { ++$c[2] }, set => sub { --$c[2] } };
ok(!$@, "wizard 2 creation error ($@)");

multi sub {
 my ($i) = @_;
 $w[$i]
}, sub {
 my ($i, $res, $err) = @_;
 ok(defined $res, "wizard $i is defined");
 ok(ref($w[$i]) eq 'SCALAR', "wizard $i is a scalar ref");
};

my $a = 0;

multi sub {
 my ($i) = @_;
 cast $a, $w[$i];
}, sub {
 my ($i, $res, $err) = @_;
 ok(!$err, "cast magic $i croaks ($err)");
 ok($res, "cast magic $i invalid");
};

my $b = $a;
for (0 .. $n - 1) { ok($c[$_] == 1, "get magic $_"); }

$a = 1;
for (0 .. $n - 1) { ok($c[$_] == 0, "set magic $_"); }

my $res = eval { dispell $a, $w[1] };
ok(!$@, "dispell magic 1 croaks ($@)");
ok($res, 'dispell magic 1 invalid');

$b = $a;
for (0, 2) { ok($c[$_] == 1, "get magic $_ after dispelled 1"); }

$a = 2;
for (0, 2) { ok($c[$_] == 0, "set magic $_ after dispelled 1"); }

$res = eval { dispell $a, $w[0] };
ok(!$@, "dispell magic 0 croaks ($@)");
ok($res, 'dispell magic 0 invalid');

$b = $a;
ok($c[2] == 1, 'get magic 2 after dispelled 1 & 0');

$a = 3;
ok($c[2] == 0, 'set magic 2 after dispelled 1 & 0');

$res = eval { dispell $a, $w[2] };
ok(!$@, "dispell magic 2 croaks ($@)");
ok($res, 'dispell magic 2 invalid');

SKIP: {
 skip 'No nice uvar magic for this perl', 24 unless VMG_UVAR;

 $n = 2;
 @c = (0) x $n;

 eval { $w[0] = wizard fetch => sub { ++$c[0] }, store => sub { --$c[0] } };
 ok(!$@, "wizard with uvar 0 creation error ($@)");
 eval { $w[1] = wizard fetch => sub { ++$c[1] }, store => sub { --$c[1] } };
 ok(!$@, "wizard with uvar 1 creation error ($@)");

 multi sub {
  my ($i) = @_;
  $w[$i]
 }, sub {
  my ($i, $res, $err) = @_;
  ok(defined $res, "wizard with uvar $i is defined");
  ok(ref($w[$i]) eq 'SCALAR', "wizard with uvar $i is a scalar ref");
 };

 my %h = (a => 1, b => 2);

 multi sub {
  my ($i) = @_;
  cast %h, $w[$i];
 }, sub {
  my ($i, $res, $err) = @_;
  ok(!$err, "cast uvar magic $i croaks ($err)");
  ok($res, "cast uvar magic $i invalid");
 };

 my $s = $h{a};
 ok($s == 1, 'fetch magic doesn\'t clobber');
 for (0 .. $n - 1) { ok($c[$_] == 1, "fetch magic $_"); }

 $h{a} = 3;
 for (0 .. $n - 1) { ok($c[$_] == 0, "store magic $_"); }
 ok($h{a} == 3, 'store magic doesn\'t clobber'); # $c[$_] == 1 for 0 .. 1

 my $res = eval { dispell %h, $w[1] };
 ok(!$@, "dispell uvar magic 1 croaks ($@)");
 ok($res, 'dispell uvar magic 1 invalid');

 $s = $h{b};
 ok($s == 2, 'fetch magic after dispelled 1 doesn\'t clobber');
 for (0) { ok($c[$_] == 2, "fetch magic $_ after dispelled 1"); }
 
 $h{b} = 4;
 for (0) { ok($c[$_] == 1, "store magic $_ after dispelled 1"); }
 ok($h{b} == 4, 'store magic doesn\'t clobber'); # $c[$_] == 2 for 0

 $res = eval { dispell %h, $w[0] };
 ok(!$@, "dispell uvar magic 0 croaks ($@)");
 ok($res, 'dispell uvar magic 0 invalid');
}

SKIP: {
 eval "use Hash::Util::FieldHash qw/fieldhash/";
 skip 'Hash::Util::FieldHash required for testing uvar interaction', 12
      unless VMG_UVAR && !$@;

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
}
