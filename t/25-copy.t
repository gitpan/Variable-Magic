#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/cast MGf_COPY/;

if (MGf_COPY) {
 plan tests => 2 + (2 * 5 + 3) + (2 * 9 + 6) + 1;
} else {
 plan skip_all => 'No copy magic for this perl';
}

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init 'copy', 'copy';

SKIP: {
 eval "use Tie::Array";
 skip 'Tie::Array required to test copy magic on arrays', 2 * 5 + 3 if $@;
 diag "Using Tie::Array $Tie::Array::VERSION" if defined $Tie::Array::VERSION;

 tie my @a, 'Tie::StdArray';
 @a = (1 .. 10);

 my $res = check { cast @a, $wiz } { }, 'cast on tied array';
 ok $res, 'copy: cast on tied array succeeded';

 check { $a[3] = 13 } { copy => 1 }, 'tied array store';

 my $s;
 check { $s = $a[3] } { copy => 1 }, 'tied array fetch';
 is $s, 13, 'copy: tied array fetch correctly';

 check { $s = exists $a[3] } { copy => 1 }, 'tied array exists';
 ok $s, 'copy: tied array exists correctly';

 check { undef @a } { }, 'tied array undef';
}

SKIP: {
 eval "use Tie::Hash";
 skip 'Tie::Hash required to test copy magic on hashes' => 2 * 9 + 6 if $@;
 diag "Using Tie::Hash $Tie::Hash::VERSION" if defined $Tie::Hash::VERSION;

 tie my %h, 'Tie::StdHash';
 %h = (a => 1, b => 2, c => 3);

 my $res = check { cast %h, $wiz } { }, 'cast on tied hash';
 ok $res, 'copy: cast on tied hash succeeded';

 check { $h{b} = 7 } { copy => 1 }, 'tied hash store';

 my $s;
 check { $s = $h{c} } { copy => 1 }, 'tied hash fetch';
 is $s, 3, 'copy: tied hash fetch correctly';

 check { $s = exists $h{a} } { copy => 1 }, 'tied hash exists';
 ok $s, 'copy: tied hash exists correctly';

 check { $s = delete $h{b} } { copy => 1 }, 'tied hash delete';
 is $s, 7, 'copy: tied hash delete correctly';

 check { my ($k, $v) = each %h } { copy => 1 }, 'tied hash each';

 my @k;
 check { @k = keys %h } { }, 'tied hash keys';
 is_deeply [ sort @k ], [ qw/a c/ ], 'copy: tied hash keys correctly';

 my @v;
 check { @v = values %h } { copy => 2 }, 'tied hash values';
 is_deeply [ sort { $a <=> $b } @v ], [ 1, 3 ], 'copy: tied hash values correctly';

 check { undef %h } { }, 'tied hash undef';
}
