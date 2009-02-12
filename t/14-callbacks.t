#!perl -T

use strict;
use warnings;

use Test::More tests => 12 + (2 * 5 + 2 * 6 + 2 * 5);

use Variable::Magic qw/wizard cast dispell VMG_OP_INFO_NAME VMG_OP_INFO_OBJECT/;

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

for ([ 'get', '$c', 'sassign' ], [ 'len', '@c', 'padav' ]) {
 my ($key, $var, $exp) = @$_;

 for my $op_info (VMG_OP_INFO_NAME, VMG_OP_INFO_OBJECT, 3) {
  my ($c, @c);

  # We must test for the $op correctness inside the callback because, if we
  # bring it out, it will go outside of the eval STRING scope, and what it
  # points to will no longer exist.
  eval {
   $wiz = wizard $key => sub {
    my $op = $_[-1];
    my $desc = "$key magic with op_info == $op_info";
    if ($op_info == 1) {
     is $op, $exp, "$desc gets the right op info";
    } elsif ($op_info == 2) {
     isa_ok $op, 'B::OP', $desc;
     is $op->name, $exp, "$desc gets the right op info";
    } else {
     is $op, undef, "$desc gets the right op info";
    }
    ()
   }, op_info => $op_info
  };
  is $@, '', "$key wizard with op_info == $op_info doesn't croak";

  eval "cast $var, \$wiz";
  is $@, '', "$key cast with op_info == $op_info doesn't croak";

  eval "my \$x = $var";
  is $@, '', "$key magic with op_info == $op_info doesn't croak";

  eval "dispell $var, \$wiz";
  is $@, '', "$key dispell with op_info == $op_info doesn't croak";
 }
}
