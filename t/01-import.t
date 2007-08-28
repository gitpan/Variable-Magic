#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

require Variable::Magic;

for (qw/wizard gensig getsig cast getdata dispell SIG_MIN SIG_MAX SIG_NBR/) {
 eval { Variable::Magic->import($_) };
 ok(!$@, 'import ' . $_);
}
