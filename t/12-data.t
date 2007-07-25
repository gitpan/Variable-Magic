#!perl -T

use Test::More tests => 14;

use Variable::Magic qw/wizard getdata cast dispell/;

my $c = 1;

my $wiz = eval {
 wizard data => sub { return { foo => 12, bar => 27 } },
         get => sub { $c += $_[1]->{foo}; $_[1]->{foo} = $c },
         set => sub { $c += $_[1]->{bar}; $_[1]->{bar} = $c }
};
ok(!$@, "wizard creation error ($@)");
ok(defined $wiz, 'wizard is defined');
ok(ref $wiz eq 'SCALAR', 'wizard is a scalar ref');

my $a = 75;
my $res = eval { cast $a, $wiz };
ok(!$@, "cast error 1 ($@)");
ok($res, 'cast error 2');

my $data = eval { getdata $a, $wiz };
ok(!$@, "getdata error 1 ($@)");
ok($res, 'getdata error 2');
ok($data && ref($data) eq 'HASH'
         && exists $data->{foo} && $data->{foo} eq 12
         && exists $data->{bar} && $data->{bar} eq 27,
   'private data creation ok');

my $b = $a;
ok($c == 13, 'get magic : pass data');
ok($data->{foo} == 13, 'get magic : data updated');

$a = 57;
ok($c == 40, 'set magic : pass data');
ok($data->{bar} == 40, 'set magic : pass data');

$res = eval { dispell $a, $wiz };
ok(!$@, "dispell error 1 ($@)");
ok($res, 'dispell error 2');
