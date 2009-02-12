#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw/wizard cast dispell VMG_UVAR VMG_OP_INFO_NAME VMG_OP_INFO_OBJECT/;

my $run;
if (VMG_UVAR) {
 plan tests => 13;
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

{
 no strict 'refs';
 cast %{"Hlagh::"}, $wiz;
}

{
 local %mg;

 eval q{
  die "ok\n";
  package Hlagh;
  our $a;
  {
   package NotHlagh;
   my $x = @Hlagh::b;
  }
 };

 is $@, "ok\n", 'stash: variables compiled fine';
 is_deeply \%mg, {
  fetch => [ qw/a b/ ],
  store => [ qw/a b/ ],
 }, 'stash: variables';
}

{
 local %mg;

 eval q{
  die "ok\n";
  package Hlagh;
  foo();
  bar();
  foo();
 };

 is $@, "ok\n", 'stash: function calls compiled fine';
 is_deeply \%mg, {
  fetch => [ qw/foo bar foo/ ],
  store => [ qw/foo bar foo/ ],
 }, 'stash: function calls';
}

{
 local %mg;

 eval q{
  package Hlagh;
  undef &foo;
 };

 is $@, '', 'stash: delete executed fine';
 is_deeply \%mg, {
  store => [ qw/foo foo foo/ ],
 }, 'stash: delete';
}

END {
 is_deeply \%mg, { }, 'stash: magic that remains at END time' if $run;
}

{
 no strict 'refs';
 dispell %{"Hlagh::"}, $wiz;
}

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

{
 no strict 'refs';
 cast %{"Hlagh::"}, $wiz;
}

eval q{
 die "ok\n";
 package Hlagh;
 meh();
};

is $@, "ok\n", 'stash: function call with op name compiled fine';

{
 no strict 'refs';
 dispell %{"Hlagh::"}, $wiz;
}

$wiz = eval $code . ', op_info => ' . VMG_OP_INFO_OBJECT;
diag $@ if $@;

{
 no strict 'refs';
 cast %{"Hlagh::"}, $wiz;
}

eval q{
 die "ok\n";
 package Hlagh;
 wat();
};

is $@, "ok\n", 'stash: function call with op object compiled fine';

{
 no strict 'refs';
 dispell %{"Hlagh::"}, $wiz;
}
