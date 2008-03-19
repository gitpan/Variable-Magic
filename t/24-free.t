#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use Variable::Magic qw/wizard cast/;

my $c = 0;
my $wiz = wizard free => sub { ++$c };
is($c, 0, 'free : create wizard');

my $n = int rand 1000;

{
 my $a = $n;

 cast $a, $wiz;
 is($c, 0, 'free : cast');
}
is($c, 1, 'free : deletion at the end of the scope');

my $a = $n;
undef $n;
is($c, 1, 'free : explicit deletion with undef()');
