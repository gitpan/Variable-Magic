#!perl -T

use Test::More tests => 33;

use Variable::Magic qw/wizard cast dispell/;

my $n = 3;
my @w;
my @c = (0) x $n;

sub multi {
 my ($cb, $tests) = @_;
 for (local $i = 0; $i < $n; ++$i) {
  my $res = eval { $cb->() };
  $tests->($res, $@);
 }
}

eval { $w[0] = wizard get => sub { ++$c[0] }, set => sub { --$c[0] } };
ok(!$@, "wizard 0 creation error ($@)");
eval { $w[1] = wizard get => sub { ++$c[1] }, set => sub { --$c[1] } };
ok(!$@, "wizard 1 creation error ($@)");
eval { $w[2] = wizard get => sub { ++$c[2] }, set => sub { --$c[2] } };
ok(!$@, "wizard 2 creation error ($@)");

multi sub {
 $w[$i]
}, sub {
 my ($res, $err) = @_;
 ok(defined $res, "wizard $i is defined");
 ok(ref($w[$i]) eq 'SCALAR', "wizard $i is a scalar ref");
};

my $a = 0;

multi sub {
 cast $a, $w[$i];
}, sub {
 my ($res, $err) = @_;
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
