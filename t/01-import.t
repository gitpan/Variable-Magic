#!perl -T

use strict;
use warnings;

use Test::More tests => 15;

require Variable::Magic;

for (qw/wizard gensig getsig cast getdata dispell SIG_MIN SIG_MAX SIG_NBR MGf_COPY MGf_DUP MGf_LOCAL VMG_UVAR VMG_COMPAT_ARRAY_PUSH_NOLEN VMG_COMPAT_ARRAY_UNDEF_CLEAR/) {
 eval { Variable::Magic->import($_) };
 ok(!$@, 'import ' . $_);
}
