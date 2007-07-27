#!perl -T

use Test::More tests => 17;

use Variable::Magic qw/wizard cast dispell/;

my @c = (0) x 5;
my @x = (0) x 5;

sub check {
 for (0 .. 4) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
}

my $wiz = wizard get   => sub { ++$c[0] },
                 set   => sub { ++$c[1] },
                 len   => sub { ++$c[2]; $_[2] },
                 clear => sub { ++$c[3] },
                 free  => sub { ++$c[4] };
ok(check(), 'hash : create wizard');

my %n = map { $_ => int rand 1000 } qw/foo bar baz qux/;
my %a = %n;

cast %a, $wiz;
ok(check(), 'hash : cast');

my $b = $a{foo};
ok(check(), 'hash : assign element to');

my %b = %a;
ok(check(), 'hash : assign to');

$b = "X%{a}Y";
ok(check(), 'hash : interpolate');

$b = \%a;
ok(check(), 'hash : reference');

my @b = @a{qw/bar qux/};
ok(check(), 'hash : slice');

%a = map { $_ => 1 } qw/a b d/;
++$x[3];
ok(check(), 'hash : assign');

$a{d} = 2;
ok(check(), 'hash : assign old element');

$a{c} = 3;
ok(check(), 'hash : assign new element');

$b = %a;
ok(check(), 'hash : buckets');

@b = keys %a;
ok(check(), 'hash : keys');

@b = values %a;
ok(check(), 'hash : values');

while (my ($k, $v) = each %a) { }
ok(check(), 'hash : each');

{
 my %b = %n;
 cast %b, $wiz;
}
++$x[4];
ok(check(), 'hash : scope end');

undef %a;
++$x[3];
ok(check(), 'hash : undef');

dispell %a, $wiz;
ok(check(), 'hash : dispel');
