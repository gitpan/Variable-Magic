#!/usr/bin/perl

use strict;
use warnings;

use lib qw{blib/arch blib/lib};
use Variable::Magic qw/wizard getsig cast dispell/;

sub foo { print STDERR "got $_[0]!\n" }
my $bar = sub { ++$_[0]; print STDERR "now set to $_[0]!\n"; };

my $a = 1;
my $sig;
{
 my $wiz = wizard get  => \&foo,
                  set  => $bar,
                  free => sub {  print STDERR "deleted!\n"; };
 $sig = getsig $wiz;
 print "my sig is $sig\n";
 cast $a, $wiz;
 ++$a;              # "got 1!", "now set to 3!"
 dispell $a, $wiz;
 cast $a, $wiz;
 my $b = 123;
 cast $b, $wiz;
}                   # "got 123!", "deleted!"
my $b = $a;         # "got 3!"
$a = 3;             # "now set to 4!"
$b = 3;             # (nothing)
dispell $a, $sig;
$a = 4;             # (nothing)
