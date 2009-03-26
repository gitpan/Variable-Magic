#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast dispell VMG_UVAR VMG_OP_INFO_NAME VMG_OP_INFO_OBJECT/;

my $run;
if (VMG_UVAR) {
 plan tests => 29;
 $run = 1;
} else {
 plan skip_all => 'uvar magic is required to test symbol table hooks';
}

our %mg;

my $code = 'wizard '
        . join (', ', map { <<CB;
$_ => sub {
 my \$d = \$_[1];
 return 0 if \$d->{guard};
 local \$d->{guard} = 1;
 push \@{\$mg{$_}}, \$_[2];
 ()
}
CB
} qw/fetch store exists delete/);

$code .= ', data => sub { +{ guard => 0 } }';

my $wiz = eval $code;
diag $@ if $@;

cast %Hlagh::, $wiz;

{
 local %mg;

 eval q{
  die "ok\n";
  package Hlagh;
  our $thing;
  {
   package NotHlagh;
   our $what = @Hlagh::stuff;
  }
 };

 is $@, "ok\n", 'stash: variables compiled fine';
 is_deeply \%mg, {
  fetch => [ qw/thing stuff/ ],
  store => [ qw/thing stuff/ ],
 }, 'stash: variables';
}

{
 local %mg;

 eval q[
  die "ok\n";
  package Hlagh;
  sub eat;
  sub shoot;
  sub leave { "bye" };
  sub shoot { "bang" };
 ];

 is $@, "ok\n", 'stash: function definitions compiled fine';
 is_deeply \%mg, {
  store => [ qw/eat shoot leave shoot/ ],
 }, 'stash: function definitions';
}

{
 local %mg;

 eval q{
  die "ok\n";
  package Hlagh;
  eat();
  shoot();
  leave();
  roam();
  yawn();
  roam();
 };

 is $@, "ok\n", 'stash: function calls compiled fine';
 is_deeply \%mg, {
  fetch => [ qw/eat shoot leave roam yawn roam/ ],
  store => [ qw/eat shoot leave roam yawn roam/ ],
 }, 'stash: function calls';
}

{
 local %mg;

 eval q{ Hlagh->shoot() };

 is $@, '', 'stash: valid method call ran fine';
 is_deeply \%mg, {
  fetch => [ qw/shoot/ ],
 }, 'stash: valid method call';
}

{
 local %mg;

 eval q[
  package Hlagher;
  our @ISA;
  BEGIN { @ISA = 'Hlagh' }
  Hlagher->shoot()
 ];

 is $@, '', 'inherited valid method call ran fine';
 is_deeply \%mg, {
  fetch => [ qw/ISA shoot/ ],
 }, 'stash: direct method call';
}

{
 local %mg;

 eval q{ Hlagh->unknown() };

 like $@, qr/^Can't locate object method "unknown" via package "Hlagh"/, 'stash: invalid method call croaked';
 is_deeply \%mg, {
  fetch => [ qw/unknown/ ],
  store => [ qw/unknown AUTOLOAD/ ],
 }, 'stash: invalid method call';
}

{
 local %mg;

 eval q{ Hlagher->also_unknown() };

 like $@, qr/^Can't locate object method "also_unknown" via package "Hlagher"/, 'stash: invalid inherited method call croaked';
 is_deeply \%mg, {
  fetch => [ qw/also_unknown AUTOLOAD/ ],
 }, 'stash: invalid method call';
}

{
 local %mg;

 eval q{
  package Hlagh;
  undef &nevermentioned;
  undef &eat;
  undef &shoot;
 };

 is $@, '', 'stash: delete executed fine';
 is_deeply \%mg, {
  store => [
   qw/nevermentioned nevermentioned eat eat shoot shoot nevermentioned/
  ],
 }, 'stash: delete';
}

END {
 is_deeply \%mg, { }, 'stash: magic that remains at END time' if $run;
}

dispell %Hlagh::, $wiz;

{
 package AutoHlagh;

 use vars qw/$AUTOLOAD/;

 sub AUTOLOAD { return $AUTOLOAD }
}

cast %AutoHlagh::, $wiz;

{
 local %mg;

 my $res = eval q{ AutoHlagh->autoloaded() };

 is $@,   '',          'stash: autoloaded method call ran fine';
 is $res, 'AutoHlagh::autoloaded',
                       'stash: autoloaded method call returned the right thing';
 is_deeply \%mg, {
  fetch => [ qw/autoloaded/ ],
  store => [ qw/autoloaded AUTOLOAD AUTOLOAD/ ],
 }, 'stash: autoloaded method call';
}

{
 package AutoHlagher;

 our @ISA;
 BEGIN { @ISA = ('AutoHlagh') }
}

{
 local %mg;

 my $res = eval q{ AutoHlagher->also_autoloaded() };

 is $@,   '',     'stash: inherited autoloaded method call ran fine';
 is $res, 'AutoHlagher::also_autoloaded',
                  'stash: inherited autoloaded method returned the right thing';
 is_deeply \%mg, {
  fetch => [ qw/also_autoloaded AUTOLOAD/ ],
  store => [ qw/AUTOLOAD/ ],
 }, 'stash: inherited autoloaded method call';
}

dispell %AutoHlagh::, $wiz;

$code = 'wizard '
        . join (', ', map { <<CB;
$_ => sub {
 my \$d = \$_[1];
 return 0 if \$d->{guard};
 local \$d->{guard} = 1;
 is \$_[3], undef, 'stash: undef op';
 ()
}
CB
} qw/fetch store exists delete/);

$code .= ', data => sub { +{ guard => 0 } }';

$wiz = eval $code . ', op_info => ' . VMG_OP_INFO_NAME;
diag $@ if $@;

cast %Hlagh::, $wiz;

eval q{
 die "ok\n";
 package Hlagh;
 meh();
};

is $@, "ok\n", 'stash: function call with op name compiled fine';

dispell %Hlagh::, $wiz;

$wiz = eval $code . ', op_info => ' . VMG_OP_INFO_OBJECT;
diag $@ if $@;

cast %Hlagh::, $wiz;

eval q{
 die "ok\n";
 package Hlagh;
 wat();
};

is $@, "ok\n", 'stash: function call with op object compiled fine';

dispell %Hlagh::, $wiz;
