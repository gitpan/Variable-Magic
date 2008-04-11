#!/usr/bin/env perl

use strict;
use warnings;

use Tie::Hash;

use lib qw{blib/arch blib/lib};
use Variable::Magic qw/wizard cast VMG_UVAR/;

use Benchmark qw/cmpthese/;

die 'Your perl does not support the nice uvar magic of 5.10.*' unless VMG_UVAR;

my @a = ('a' .. 'z');

tie my %t, 'Tie::StdHash';
$t{$a[$_]} = $_ for 0 .. $#a;

my $wiz = wizard fetch => sub { 0 }, store => sub { 0 };
my %v;
$v{$a[$_]} = $_ for 0 .. $#a;
cast %v, $wiz;

my $x = 0;

cmpthese -3, {
 'tie'  => sub { my ($x, $y) = map @a[$x++ % @a], 1 .. 2; my $a = $t{$x}; $t{$y} = $a },
 'v::m' => sub { my ($x, $y) = map @a[$x++ % @a], 1 .. 2; my $a = $v{$x}; $v{$y} = $a }
};
