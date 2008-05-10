#!perl -T

use strict;
use warnings;

use Test::More tests => 32;

use Variable::Magic qw/wizard getdata cast dispell SIG_MIN/;

my $c = 1;

my $sig = SIG_MIN;
my $wiz = eval {
 wizard  sig => $sig,
        data => sub { return { foo => $_[1] || 12, bar => $_[3] || 27 } },
         get => sub { $c += $_[1]->{foo}; $_[1]->{foo} = $c },
         set => sub { $c += $_[1]->{bar}; $_[1]->{bar} = $c }
};
is($@, '',             'wizard doesn\'t croak');
ok(defined $wiz,       'wizard is defined');
is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');

my $a = 75;
my $res = eval { cast $a, $wiz };
is($@, '', 'cast doesn\'t croak');
ok($res,   'cast returns true');

my $data = eval { getdata $a, $wiz };
is($@, '', 'getdata from wizard doesn\'t croak');
ok($res,   'getdata from wizard returns true');
is_deeply($data, { foo => 12, bar => 27 },
           'getdata from wizard return value is ok');

$data = eval { getdata my $b, $wiz };
is($@, '',       'getdata from non-magical scalar doesn\'t croak');
is($data, undef, 'getdata from non-magical scalar returns undef');

$data = eval { getdata $a, $sig };
is($@, '', 'getdata from sig doesn\'t croak');
ok($res,   'getdata from sig returns true');
is_deeply($data, { foo => 12, bar => 27 },
           'getdata from sig return value is ok');

my $b = $a;
is($c,           13, 'get magic : pass data');
is($data->{foo}, 13, 'get magic : data updated');

$a = 57;
is($c,           40, 'set magic : pass data');
is($data->{bar}, 40, 'set magic : pass data');

$data = eval { getdata $a, ($sig + 1) };
is($@, '',       'getdata from invalid sig doesn\'t croak');
is($data, undef, 'getdata from invalid sig returns undef');

$data = eval { getdata $a, undef };
like($@, qr/Invalid\s+wizard\s+object/, 'getdata from undef croaks');
is($data, undef, 'getdata from undef doesn\'t return anything');

$res = eval { dispell $a, $wiz };
is($@, '', 'dispell doesn\'t croak');
ok($res,   'dispell returns true');

$res = eval { cast $a, $wiz, qw/z j t/ };
is($@, '', 'cast with arguments doesn\'t croak');
ok($res,   'cast with arguments returns true');

$data = eval { getdata $a, $wiz };
is($@, '', 'getdata from wizard with arguments doesn\'t croak');
ok($res,   'getdata from wizard with arguments returns true');
is_deeply($data, { foo => 'z', bar => 't' },
           'getdata from wizard with arguments return value is ok');

$wiz = wizard get => sub { };
dispell $a, $sig;
$a = 63;
$res = eval { cast $a, $wiz };
is($@, '', 'cast non-data wizard doesn\'t croak');
ok($res,   'cast non-data wizard returns true');

$data = eval { getdata $a, $wiz };
is($@, '',       'getdata from non-data wizard doesn\'t croak');
is($data, undef, 'getdata from non-data wizard invalid returns undef');
