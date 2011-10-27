#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw<cast dispell>;

plan tests => 2 + ((2 * 5 + 3) + (2 * 2 + 1)) + (2 * 9 + 6) + 1;

use lib 't/lib';
use Variable::Magic::TestWatcher;
use Variable::Magic::TestValue;

my $wiz = init_watcher 'copy', 'copy';

SKIP: {
 my $has_tie_array = do { local $@; eval { require Tie::Array; 1 } };
 skip 'Tie::Array required to test copy magic on arrays'
                             => (2 * 5 + 3) + (2 * 2 + 1) unless $has_tie_array;
 defined and diag "Using Tie::Array $_" for $Tie::Array::VERSION;

 tie my @a, 'Tie::StdArray';
 @a = (1 .. 10);

 my $res = watch { cast @a, $wiz } { }, 'cast on tied array';
 ok $res, 'copy: cast on tied array succeeded';

 watch { $a[3] = 13 } { copy => 1 }, 'tied array store';

 my $s = watch { $a[3] } { copy => 1 }, 'tied array fetch';
 is $s, 13, 'copy: tied array fetch correctly';

 $s = watch { exists $a[3] } { copy => 1 }, 'tied array exists';
 ok $s, 'copy: tied array exists correctly';

 watch { undef @a } { }, 'tied array undef';

 {
  tie my @val, 'Tie::StdArray';
  @val = (4 .. 6);

  my $wv = init_value @val, 'copy', 'copy';

  value { $val[3] = 8 } [ 4 .. 6 ];

  dispell @val, $wv;
  is_deeply \@val, [ 4 .. 6, 8 ], 'copy: value after';
 }
}

SKIP: {
 my $has_tie_hash = do { local $@; eval { require Tie::Hash; 1 } };
 skip 'Tie::Hash required to test copy magic on hashes'
                                              => 2 * 9 + 6 unless $has_tie_hash;
 defined and diag "Using Tie::Hash $_" for $Tie::Hash::VERSION;

 tie my %h, 'Tie::StdHash';
 %h = (a => 1, b => 2, c => 3);

 my $res = watch { cast %h, $wiz } { }, 'cast on tied hash';
 ok $res, 'copy: cast on tied hash succeeded';

 watch { $h{b} = 7 } { copy => 1 }, 'tied hash store';

 my $s = watch { $h{c} } { copy => 1 }, 'tied hash fetch';
 is $s, 3, 'copy: tied hash fetch correctly';

 $s = watch { exists $h{a} } { copy => 1 }, 'tied hash exists';
 ok $s, 'copy: tied hash exists correctly';

 $s = watch { delete $h{b} } { copy => 1 }, 'tied hash delete';
 is $s, 7, 'copy: tied hash delete correctly';

 watch { my ($k, $v) = each %h } { copy => 1 }, 'tied hash each';

 my @k = watch { keys %h } { }, 'tied hash keys';
 is_deeply [ sort @k ], [ qw<a c> ], 'copy: tied hash keys correctly';

 my @v = watch { values %h } { copy => 2 }, 'tied hash values';
 is_deeply [ sort { $a <=> $b } @v ], [ 1, 3 ], 'copy: tied hash values correctly';

 watch { undef %h } { }, 'tied hash undef';
}
