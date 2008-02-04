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
 ok(ref $wiz eq 'SCALAR', 'wizard is a scalar ref');

 my $res = eval { cast $wiz, $wiz };
 ok(!$@, "cast on self croaks ($@)");
 ok($res, 'cast on self invalid');

 my $w = $wiz;
 ok($c == 1, 'magic works correctly on self');

 $res = eval { dispell $wiz, $wiz };
 ok(!$@, "dispell on self croaks ($@)");
 ok($res, 'dispell on self invalid');

 $w = $wiz;
 ok($c == 1, 'magic is no longer invoked on self when dispelled');

 $res = eval { cast $wiz, $wiz, $wiz };
 ok(!$@, "re-cast on self croaks ($@)");
 ok($res, 're-cast on self invalid');

 $w = getdata $wiz, $wiz;
 ok($c == 1, 'getdata on magical self doesn\'t trigger callbacks');
 # ok(getsig($w) == getsig($wiz), 'getdata returns the correct wizard');

 $res = eval { dispell $wiz, $wiz };
 ok(!$@, "re-dispell on self croaks ($@)");
 ok($res, 're-dispell on self invalid');

 $res = eval { cast $wiz, $wiz };
 ok(!$@, "re-re-cast on self croaks ($@)");
 ok($res, 're-re-cast on self invalid');
}

# ok($c == 0, 'magic destructor is called');
