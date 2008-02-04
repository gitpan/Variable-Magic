#!perl -T

use strict;
use warnings;

use Test::More tests => 18;

use Variable::Magic qw/wizard cast dispell MGf_COPY VMG_UVAR VMG_COMPAT_HASH_LISTASSIGN_COPY/;

my @c = (0) x 12;
my @x = (0) x 12;

sub check {
 for (0 .. 11) { return 0 unless $c[$_] == $x[$_]; }
 return 1;
}

my $wiz = wizard get   => sub { ++$c[0] },
                 set   => sub { ++$c[1] },
                 len   => sub { ++$c[2]; $_[2] },
                 clear => sub { ++$c[3] },
                 free  => sub { ++$c[4] },
                 copy  => sub { ++$c[5] },
                 dup   => sub { ++$c[6] },
                 local => sub { ++$c[7] },
                 fetch => sub { ++$c[8] },
                 store => sub { ++$c[9] },
                 'exists' => sub { ++$c[10] },
                 'delete' => sub { ++$c[11] };
ok(check(), 'hash : create wizard');

my %n = map { $_ => int rand 1000 } qw/foo bar baz qux/;
my %a = %n;

cast %a, $wiz;
ok(check(), 'hash : cast');

my $b = $a{foo};
++$x[5] if MGf_COPY;
++$x[8] if VMG_UVAR;
ok(check(), 'hash : assign element to');

my %b = %a;
ok(check(), 'hash : assign to');

$b = "X%{a}Y";
ok(check(), 'hash : interpolate');

$b = \%a;
ok(check(), 'hash : reference');

my @b = @a{qw/bar qux/};
$x[5] += 2 if MGf_COPY;
$x[8] += 2 if VMG_UVAR;
ok(check(), 'hash : slice');

%a = (a => 1, d => 3);
++$x[3];
$x[5] += 2 if VMG_COMPAT_HASH_LISTASSIGN_COPY;
$x[9] += 2 if VMG_UVAR;
ok(check(), 'hash : assign from list');

%a = map { $_ => 1 } qw/a b d/;
++$x[3];
$x[5] += 3 if VMG_COMPAT_HASH_LISTASSIGN_COPY;
$x[9] += 3 if VMG_UVAR;
ok(check(), 'hash : assign from map');

$a{d} = 2;
++$x[5] if MGf_COPY;
++$x[9] if VMG_UVAR;
ok(check(), 'hash : assign old element');

$a{c} = 3;
++$x[5] if MGf_COPY;
++$x[9] if VMG_UVAR;
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
