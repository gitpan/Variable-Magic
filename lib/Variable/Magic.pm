package Variable::Magic;

use strict;
use warnings;

use Carp qw/croak/;

=head1 NAME

Variable::Magic - Associate user-defined magic to variables from Perl.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Variable::Magic qw/wizard cast dispell/;

    my $wiz = wizard set => sub { print STDERR "now set to ${$_[0]}!\n" };
    my $a = 1;
    cast $a, $wiz;
    $a = 2;          # "now set to 2!"
    dispell $a, $wiz;
    $a = 3           # (nothing)

=head1 DESCRIPTION

Magic is Perl way of enhancing objects. This mechanism let the user add extra data to any variable and overload syntaxical operations (such as access, assignation or destruction) that can be applied to it. With this module, you can add your own magic to any variable without the pain of the C API.

The operations that can be overloaded are :

=over 4

=item C<get>

This magic is invoked when the variable is evaluated (does not include array/hash subscripts and slices).

=item C<set>

This one is triggered each time the value of the variable changes (includes array/hash subscripts and slices).

=item C<len>

This magic is a little special : it is called when the 'size' or the 'length' of the variable has to be known by Perl. Typically, it's the magic involved when an array is evaluated in scalar context, but also on array assignation and loops (C<for>, C<map> or C<grep>). The callback has then to return the length as an integer.

=item C<clear>

This magic is invoked when the variable is reset, such as when an array is emptied. Please note that this is different from undefining the variable, even though the magic is called when the clearing is a result of the undefine (e.g. for an array, but actually a bug prevent it to work before perl 5.9.5 - see the L<history|/PERL MAGIC HISTORY>).

=item C<free>

This last one can be considered as an object destructor. It happens when the variable goes out of scope (with the exception of global scope), but not when it is undefined.

=back

To prevent any clash between different magics defined with this module, an unique numerical signature is attached to each kind of magic (i.e. each set of callbacks for magic operations).

=head1 PERL MAGIC HISTORY

The places where magic is invoked have changed a bit through perl history. Here's a little list of the most recent ones.

=head2 B<5.9.3>

=over 4

=item 'len' magic is no longer called when pushing an element into a magic array.

=back

=head2 B<5.9.5>

=over 4

=item 'clear' magic wasn't invoked when undefining an array. The bug is fixed as of this version.

=back

=head1 CONSTANTS

=head2 C<SIG_MIN>

The minimum integer used as a signature for user-defined magic.

=head2 C<SIG_MAX>

The maximum integer used as a signature for user-defined magic.

=head2 C<SIG_NBR>

    SIG_NBR = SIG_MAX - SIG_MIN + 1

=head1 FUNCTIONS

=cut

require XSLoader;

XSLoader::load(__PACKAGE__, $VERSION);

=head2 C<wizard>

    wizard sig => .., data => ..., get => .., set => .., len => .., clear => .., free => ..

This function creates a 'wizard', an opaque type that holds the magic information. It takes a list of keys / values as argument, whose keys can be :

=over 4

=item C<'sig'>

The numerical signature. If not specified or undefined, a random signature is generated. If the signature matches an already defined magic, then the existant magic object is returned.

=item C<'data'>

A code reference to a private data constructor. It is called each time this magic is cast on a variable, and the scalar returned is used as private data storage for it. C<$_[0]> is a reference to the magic object and C<@_[1 .. @_-1]> are all extra arguments that were passed to L</cast>.

=item C<'get'>, C<'set'>, C<'len'>, C<'clear'> and C<'free'>

Code references to corresponding magic callbacks. You don't have to specify all of them : the magic associated with undefined entries simply won't be hooked. In those callbacks, C<$_[0]> is a reference to the magic object and C<$_[1]> is the private data (or C<undef> when no private data constructor was supplied). In the special case of C<len> magic and when the variable is an array, C<$_[2]> contains its normal length.

=back

    # A simple scalar tracer
    my $wiz = wizard get  => sub { print STDERR "got ${$_[0]}\n" },
                     set  => sub { print STDERR "set to ${$_[0]}\n" },
                     free => sub { print STDERR "${$_[0]} was deleted\n" }

=cut

sub wizard {
 croak 'Wrong number of arguments for wizard()' if @_ % 2;
 my %opts = @_;
 return _wizard(map { $opts{$_} } qw/sig get set len clear free data/);
}

=head2 C<gensig>

With this tool, you can manually generate random magic signature between SIG_MIN and SIG_MAX inclusive. That's the way L</wizard> creates them when no signature is supplied.

    # Generate a signature
    my $sig = gensig;

=head2 C<getsig>

    getsig $wiz

This accessor returns the magic signature of this wizard.

    # Get $wiz signature
    my $sig = getsig $wiz;

=head2 C<cast>

    cast [$@%&*]var, [$wiz|$sig], ...

This function associates C<$wiz> magic to the variable supplied, without overwriting any other kind of magic. You can also supply the numeric signature C<$sig> instead of C<$wiz>. It returns true on success or when C<$wiz> magic is already present, C<0> on error, and C<undef> when no magic corresponds to the given signature (in case C<$sig> was supplied). All extra arguments specified after C<$wiz> are passed to the private data constructor.

    # Casts $wiz onto $x. If $wiz isn't a signature, undef can't be returned.
    my $x;
    die 'error' unless cast $x, $wiz;

=head2 C<getdata>

    getdata [$@%&*]var, [$wiz|$sig]

This accessor fetches the private data associated with the magic C<$wiz> (or the signature C<$sig>) in the variable. C<undef> is returned when no such magic or data is found, or when C<$sig> does not represent a current valid magic object.

    # Get the attached data.
    my $data = getdata $x, $wiz or die 'no such magic or magic has no data';

=head2 C<dispell>

    dispell [$@%&*]variable, [$wiz|$sig]

The exact opposite of L</cast> : it dissociates C<$wiz> magic from the variable. You can also pass the magic signature C<$sig> as the second argument. True is returned on success, C<0> on error or when no magic represented by C<$wiz> could be found in the variable, and C<undef> when no magic corresponds to the given signature (in case C<$sig> was supplied).

    # Dispell now. If $wiz isn't a signature, undef can't be returned.
    die 'no such magic or error' unless dispell $x, $wiz;

=head1 EXPORT

The functions L</wizard>, L</gensig>, L</getsig>, L</cast>, L</getdata> and L</dispell> are only exported on request. All of them are exported by the tags C<':funcs'> and C<':all'>.

The constants L</SIG_MIN>, L</SIG_MAX> and L</SIG_NBR> are also only exported on request. They are all exported by the tags C<':consts'> and C<':all'>.

=cut

use base qw/Exporter/;

our @EXPORT         = ();
our %EXPORT_TAGS    = (
 'funcs' =>  [ qw/wizard gensig getsig cast getdata dispell/ ],
 'consts' => [ qw/SIG_MIN SIG_MAX SIG_NBR/ ]
);
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;

=head1 DEPENDENCIES

L<Carp> (standard since perl 5), L<XSLoader> (standard since perl 5.006).

Tests use L<Symbol> (standard since perl 5.002).

=head1 SEE ALSO

L<perlguts> and L<perlapi> for internal information about magic.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>

You can contact me by mail or on #perl @ FreeNode (Prof_Vince).

=head1 BUGS

Please report any bugs or feature requests to
C<bug-variable-magic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Magic>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Variable::Magic

=head1 COPYRIGHT & LICENSE

Copyright 2007 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Variable::Magic
