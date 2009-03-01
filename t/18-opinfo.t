#!perl -T

use strict;
use warnings;

use Test::More tests => 11 * (5 + 6) + 4 + 5;

use Config qw/%Config/;

use Variable::Magic qw/wizard cast dispell VMG_OP_INFO_NAME VMG_OP_INFO_OBJECT/;

sub Variable::Magic::TestPkg::foo { }

my $aelem    = $] <= 5.008003 ? 'aelem' : 'aelemfast';
my $aelem_op = $Config{useithreads} ? 'B::PADOP' : 'B::SVOP';

our @o;

my @tests = (
 [ 'len', '@c',    undef,     'my $x = @c',        [ 'padav',   'B::OP'     ] ],
 [ 'get', '$c[0]', undef,     'my $x = $c[0]',     [ $aelem,    'B::OP'     ] ],
 [ 'get', '$o[0]', undef,     'my $x = $o[0]',   [ 'aelemfast', $aelem_op   ] ],
 [ 'get', '$c',    undef,     '++$c',              [ 'preinc',  'B::UNOP'   ] ],
 [ 'get', '$c',    '$c = 1',  '$c ** 2',           [ 'pow',     'B::BINOP'  ] ],
 [ 'get', '$c',    undef,     'my $x = $c',        [ 'sassign', 'B::BINOP'  ] ],
 [ 'get', '$c',    undef,     '1 if $c',           [ 'and',     'B::LOGOP'  ] ],
 [ 'set', '$c',    undef,     'bless \$c, "main"', [ 'bless',   'B::LISTOP' ] ],
 [ 'get', '$c',    '$c = ""', '$c =~ /x/',         [ 'match',   'B::PMOP'   ] ],
 [ 'get', '$c',    '$c = "Variable::Magic::TestPkg"',
                              '$c->foo()',    [ 'method_named', 'B::SVOP'   ] ],
 [ 'get', '$c',    '$c = ""', '$c =~ y/x/y/',      [ 'trans',   'B::PVOP'   ] ],
);

for (@tests) {
 my ($key, $var, $init, $test, $exp) = @$_;

 for my $op_info (VMG_OP_INFO_NAME, VMG_OP_INFO_OBJECT) {
  our $done;
  my ($c, @c);
  my $wiz;

  # We must test for the $op correctness inside the callback because, if we
  # bring it out, it will go outside of the eval STRING scope, and what it
  # points to will no longer exist.
  eval {
   $wiz = wizard $key => sub {
    return if $done;
    my $op = $_[-1];
    my $desc = "$key magic with op_info == $op_info";
    if ($op_info == VMG_OP_INFO_NAME) {
     is $op, $exp->[0], "$desc gets the right op info";
    } elsif ($op_info == VMG_OP_INFO_OBJECT) {
     isa_ok $op, $exp->[1], $desc;
     is $op->name, $exp->[0], "$desc gets the right op info";
    } else {
     is $op, undef, "$desc gets the right op info";
    }
    $done = 1;
    ()
   }, op_info => $op_info
  };
  is $@, '', "$key wizard with op_info == $op_info doesn't croak";

  local $done = 0;

  eval $init if defined $init;

  eval "cast $var, \$wiz";
  is $@, '', "$key cast with op_info == $op_info doesn't croak";

  eval $test;
  is $@, '', "$key magic with op_info == $op_info doesn't croak";

  eval "dispell $var, \$wiz";
  is $@, '', "$key dispell with op_info == $op_info doesn't croak";
 }
}

{
 my $c;

 my $op_info = VMG_OP_INFO_OBJECT;
 my $wiz = eval {
  wizard free => sub {
    my $op = $_[-1];
    my $desc = "free magic with op_info == $op_info";
    isa_ok $op, 'B::OP', $desc;
    is $op->name, 'leaveloop', "$desc gets the right op info";
    ();
   }, op_info => $op_info;
 };
 is $@, '', "get wizard with out of bounds op_info doesn't croak";

 eval { cast $c, $wiz };
 is $@, '', "get cast with out of bounds op_info doesn't croak";
}

{
 my $c;

 my $wiz = eval {
  wizard get => sub {
    is $_[-1], undef, 'get magic with out of bounds op_info';
   },
   op_info => 3;
 };
 is $@, '', "get wizard with out of bounds op_info doesn't croak";

 eval { cast $c, $wiz };
 is $@, '', "get cast with out of bounds op_info doesn't croak";

 eval { my $x = $c };
 is $@, '', "get magic with out of bounds op_info doesn't croak";

 eval { dispell $c, $wiz };
 is $@, '', "get dispell with out of bounds op_info doesn't croak";
}
