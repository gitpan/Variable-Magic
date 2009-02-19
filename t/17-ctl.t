#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 1;

use Variable::Magic qw/wizard cast/;

my $wiz;

eval {
 $wiz = wizard data => sub { $_[1]->() };
 my $x;
 cast $x, $wiz, sub { die "carrot" };
};

like $@, qr/carrot/, 'die in data callback';

eval {
 $wiz = wizard data => sub { $_[1] },
               set  => sub { $_[1]->(); () };
 my $x;
 cast $x, $wiz, sub { die "lettuce" };
 $x = 5;
};

like $@, qr/lettuce/, 'die in set callback';

my $res = eval {
 $wiz = wizard data => sub { $_[1] },
               len  => sub { $_[1]->(); () };
 my @a = (1 .. 3);
 cast @a, $wiz, sub { die "potato" };
 @a;
};

like $@, qr/potato/, 'die in len callback';

eval {
 $wiz = wizard data => sub { $_[1] },
               free => sub { $_[1]->(); () };
 my $x;
 cast $x, $wiz, sub { die "spinach" };
};

like $@, qr/spinach/, 'die in free callback';

# Inspired by B::Hooks::EndOfScope

eval q{BEGIN {
 $wiz = wizard data => sub { $_[1]->() };
 my $x;
 cast $x, $wiz, sub { die "pumpkin" };
}};

like $@, qr/pumpkin/, 'die in data callback in BEGIN';

eval q{BEGIN {
 $wiz = wizard data => sub { $_[1] },
               free => sub { $_[1]->(); () };
 $^H |= 0x020000;
 cast %^H, $wiz, sub { die "macaroni" };
}};

like $@, qr/macaroni/, 'die in free callback in BEGIN';

eval q{BEGIN {
 $wiz = wizard data => sub { $_[1] },
               len  => sub { $_[1]->(); $_[2] },
               free => sub { my $x = @{$_[0]}; () };
 my @a = (1 .. 5);
 cast @a, $wiz, sub { die "pepperoni" };
}};

like $@, qr/pepperoni/, 'die in len callback in BEGIN';

use lib 't/lib';
eval "use Variable::Magic::TestDieRequired";

like $@, qr/turnip/, 'die in required with localized hash gets the right error message';
