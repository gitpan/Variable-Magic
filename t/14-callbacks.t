#!perl -T

use strict;
use warnings;

use Test::More tests => 12;

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

my @callers;
$wiz = wizard get => sub {
 my @c;
 my $i = 0;
 while (@c = caller $i++) {
  push @callers, [ @c[0, 1, 2] ];
 }
};

my $b;
cast $b, $wiz;

my $u = $b;
is_deeply(\@callers, [
 [ 'main', $0, __LINE__-2 ],
], 'caller into callback returns the right thing');

@callers = ();
$u = $b;
is_deeply(\@callers, [
 [ 'main', $0, __LINE__-2 ],
], 'caller into callback returns the right thing (second time)');

{
 @callers = ();
 my $u = $b;
 is_deeply(\@callers, [
  [ 'main', $0, __LINE__-2 ],
 ], 'caller into callback into block returns the right thing');
}

@callers = ();
eval { my $u = $b };
is($@, '', 'caller into callback doesn\'t croak');
is_deeply(\@callers, [
 ([ 'main', $0, __LINE__-3 ]) x 2,
], 'caller into callback into eval returns the right thing');
