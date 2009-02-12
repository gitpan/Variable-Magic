#!perl -T

use strict;
use warnings;

use Test::More tests => 21;

require Variable::Magic;

for (qw/wizard gensig getsig cast getdata dispell
        SIG_MIN SIG_MAX SIG_NBR
        MGf_COPY MGf_DUP MGf_LOCAL VMG_UVAR
        VMG_COMPAT_ARRAY_PUSH_NOLEN  VMG_COMPAT_ARRAY_UNSHIFT_NOLEN_VOID
        VMG_COMPAT_ARRAY_UNDEF_CLEAR VMG_COMPAT_SCALAR_LENGTH_NOLEN
        VMG_PERL_PATCHLEVEL
        VMG_THREADSAFE
        VMG_OP_INFO_NAME VMG_OP_INFO_OBJECT/) {
 eval { Variable::Magic->import($_) };
 is($@, '', 'import ' . $_);
}
