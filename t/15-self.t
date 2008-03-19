#!perl -T

use strict;
use warnings;

use Test::More tests => 16;

use Variable::Magic qw/wizard cast dispell getdata getsig/;

my $c = 0;

{
 my $wiz = eval {
  wizard data => sub { $_[0] },
         get  => sub { ++$c },
         free => sub { --$c }
 };
 ok(!$@, "wizard creation error ($@)");
 ok(defined $wiz, 'wizard is defined');
 is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');

 my $res = eval { cast $wiz, $wiz };
 ok(!$@, "cast on self doesn't croak ($@)");
 ok($res, 'cast on self is valid');

 my $w = $wiz;
 is($c, 1, 'magic works correctly on self');

 $res = eval { dispell $wiz, $wiz };
 ok(!$@, "dispell on self doesn't croak ($@)");
 ok($res, 'dispell on self is valid');

 $w = $wiz;
 is($c, 1, 'magic is no longer invoked on self when dispelled');

 $res = eval { cast $wiz, $wiz, $wiz };
 ok(!$@, "re-cast on self doesn't croak ($@)");
 ok($res, 're-cast on self is valid');

 $w = getdata $wiz, $wiz;
 is($c, 1, 'getdata on magical self doesn\'t trigger callbacks');
 # is(getsig($w), getsig($wiz), 'getdata returns the correct wizard');

 $res = eval { dispell $wiz, $wiz };
 ok(!$@, "re-dispell on self doesn't croak ($@)");
 ok($res, 're-dispell on self is valid');

 $res = eval { cast $wiz, $wiz };
 ok(!$@, "re-re-cast on self doesn't croak ($@)");
 ok($res, 're-re-cast on self is valid');
}

# is($c, 0, 'magic destructor is called');
