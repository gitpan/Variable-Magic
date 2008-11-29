package Variable::Magic;

use 5.007003;

use strict;
use warnings;

use Carp qw/croak/;

=head1 NAME

Variable::Magic - Associate user-defined magic to variables from Perl.

=head1 VERSION

Version 0.26

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.26';
}

=head1 SYNOPSIS

    use Variable::Magic qw/wizard cast dispell/;

    my $wiz = wizard set => sub { print STDERR "now set to ${$_[0]}!\n" };
    my $a = 1;
    cast $a, $wiz;
    $a = 2;          # "now set to 2!"
    dispell $a, $wiz;
    $a = 3           # (nothing)

=head1 DESCRIPTION

Magic is Perl way of enhancing objects. This mechanism let the user add extra data to any variable and hook syntaxical operations (such as access, assignation or destruction) that can be applied to it. With this module, you can add your own magic to any variable without the pain of the C API.

Magic differs from tieing and overloading in several ways :

=over 4

=item *

Magic isn't copied on assignation (as for blessed references) : you attach it to variables, not values.

=item *

It doesn't replace the original semantics : magic callbacks trigger before the original action take place, and can't prevent it to happen.

=item *

It's mostly invisible at the Perl level : magical and non-magical variables cannot be distinguished with C<ref>, C<reftype> or another trick.

=item *

It's notably faster, since perl's way of handling magic is lighter by nature, and there's no need for any method resolution.

=back

The operations that can be overloaded are :

=over 4

=item *

C<get>

This magic is invoked when the variable is evaluated (does not include array/hash subscripts and slices).

=item *

C<set>

This one is triggered each time the value of the variable changes (includes array/hash subscripts and slices).

=item *

C<len>

This magic is a little special : it is called when the 'size' or the 'length' of the variable has to be known by Perl. Typically, it's the magic involved when an array is evaluated in scalar context, but also on array assignation and loops (C<for>, C<map> or C<grep>). The callback has then to return the length as an integer.

=item *

C<clear>

This magic is invoked when the variable is reset, such as when an array is emptied. Please note that this is different from undefining the variable, even though the magic is called when the clearing is a result of the undefine (e.g. for an array, but actually a bug prevent it to work before perl 5.9.5 - see the L<history|/PERL MAGIC HISTORY>).

=item *

C<free>

This one can be considered as an object destructor. It happens when the variable goes out of scope (with the exception of global scope), but not when it is undefined.

=item *

C<copy>

This magic only applies to tied arrays and hashes. It fires when you try to access or change their elements. It is available on your perl iff C<MGf_COPY> is true.

=item *

C<dup>

Invoked when the variable is cloned across threads. Currently not available.

=item *

C<local>

When this magic is set on a variable, all subsequent localizations of the variable will trigger the callback. It is available on your perl iff C<MGf_LOCAL> is true.

=back

The following actions only apply to hashes and are available iff C<VMG_UVAR> is true. They are referred to as C<uvar> magics.

=over 4

=item *

C<fetch>

This magic happens each time an element is fetched from the hash.

=item *

C<store>

This one is called when an element is stored into the hash.

=item *

C<exists>

This magic fires when a key is tested for existence in the hash.

=item *

C<delete>

This last one triggers when a key is deleted in the hash, regardless of whether the key actually exists in it.

=back

You can refer to the tests to have more insight of where the different magics are invoked.

To prevent any clash between different magics defined with this module, an unique numerical signature is attached to each kind of magic (i.e. each set of callbacks for magic operations).

=head1 PERL MAGIC HISTORY

The places where magic is invoked have changed a bit through perl history. Here's a little list of the most recent ones.

=over 4

=item *

B<5.6.x>

I<p14416> : 'copy' and 'dup' magic.

=item *

B<5.8.9>

I<p28160> : Integration of I<p25854> (see below).

I<p32542> : Integration of I<p31473> (see below).

=item *

B<5.9.3>

I<p25854> : 'len' magic is no longer called when pushing an element into a magic array.

I<p26569> : 'local' magic.

=item *

B<5.9.5>

I<p31064> : Meaningful 'uvar' magic.

I<p31473> : 'clear' magic wasn't invoked when undefining an array. The bug is fixed as of this version.

=item *

B<5.10.0>

Since C<PERL_MAGIC_uvar> is uppercased, C<hv_magic_check()> triggers 'copy' magic on hash stores for (non-tied) hashes that also have 'uvar' magic.

=item *

B<5.11.x>

I<p32969> : 'len' magic is no longer invoked when calling C<length> with a magical scalar.

I<p34908> : 'len' magic is no longer called when pushing / unshifting an element into a magical array in void context. The C<push> part was already covered by I<p25854>.

=back

=head1 CONSTANTS

=head2 C<SIG_MIN>

The minimum integer used as a signature for user-defined magic.

=head2 C<SIG_MAX>

The maximum integer used as a signature for user-defined magic.

=head2 C<SIG_NBR>

    SIG_NBR = SIG_MAX - SIG_MIN + 1

=head2 C<MGf_COPY>

Evaluates to true iff the 'copy' magic is available.

=head2 C<MGf_DUP>

Evaluates to true iff the 'dup' magic is available.

=head2 C<MGf_LOCAL>

Evaluates to true iff the 'local' magic is available.

=head2 C<VMG_UVAR>

When this constant is true, you can use the C<fetch,store,exists,delete> callbacks on hashes.

=head2 C<VMG_COMPAT_ARRAY_PUSH_NOLEN>

True for perls that don't call 'len' magic when you push an element in a magical array.

=head2 C<VMG_COMPAT_ARRAY_UNSHIFT_NOLEN_VOID>

True for perls that don't call 'len' magic when you unshift in void context an element in a magical array.

=head2 C<VMG_COMPAT_ARRAY_UNDEF_CLEAR>

True for perls that call 'clear' magic when undefining magical arrays.

=head2 C<VMG_COMPAT_SCALAR_LENGTH_NOLEN>

True for perls that don't call 'len' magic when taking the C<length> of a magical scalar.

=head2 C<VMG_PERL_PATCHLEVEL>

The perl patchlevel this module was built with, or C<0> for non-debugging perls.

=head2 C<VMG_THREADSAFE>

True iff this module could have been built with thread-safety features enabled.

=head1 FUNCTIONS

=cut

BEGIN {
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

=head2 C<wizard>

    wizard sig    => ...,
           data   => sub { ... },
           get    => sub { my ($ref, $data) = @_; ... },
           set    => sub { my ($ref, $data) = @_; ... },
           len    => sub { my ($ref, $data, $len) = @_; ... ; return $newlen; },
           clear  => sub { my ($ref, $data) = @_; ... },
           free   => sub { my ($ref, $data) = @_, ... },
           copy   => sub { my ($ref, $data, $key, $elt) = @_; ... },
           local  => sub { my ($ref, $data) = @_; ... },
           fetch  => sub { my ($ref, $data, $key) = @_; ... },
           store  => sub { my ($ref, $data, $key) = @_; ... },
           exists => sub { my ($ref, $data, $key) = @_; ... },
           delete => sub { my ($ref, $data, $key) = @_; ... }

This function creates a 'wizard', an opaque type that holds the magic information. It takes a list of keys / values as argument, whose keys can be :

=over 4

=item *

C<sig>

The numerical signature. If not specified or undefined, a random signature is generated. If the signature matches an already defined magic, then the existant magic object is returned.

=item *

C<data>

A code reference to a private data constructor. It is called each time this magic is cast on a variable, and the scalar returned is used as private data storage for it. C<$_[0]> is a reference to the magic object and C<@_[1 .. @_-1]> are all extra arguments that were passed to L</cast>.

=item *

C<get>, C<set>, C<len>, C<clear>, C<free>, C<copy>, C<local>, C<fetch>, C<store>, C<exists> and C<delete>

Code references to corresponding magic callbacks. You don't have to specify all of them : the magic associated with undefined entries simply won't be hooked. In those callbacks, C<$_[0]> is always a reference to the magic object and C<$_[1]> is always the private data (or C<undef> when no private data constructor was supplied). In the special case of C<len> magic and when the variable is an array, C<$_[2]> contains its normal length. C<$_[2]> is the current key in C<copy>, C<fetch>, C<store>, C<exists> and C<delete> callbacks, although for C<copy> it may just be a copy of the actual key so it's useless to (for example) cast magic on it. C<copy> magic also receives the current element (i.e. the value) in C<$_[3]>.

=back

    # A simple scalar tracer
    my $wiz = wizard get  => sub { print STDERR "got ${$_[0]}\n" },
                     set  => sub { print STDERR "set to ${$_[0]}\n" },
                     free => sub { print STDERR "${$_[0]} was deleted\n" }

=cut

sub wizard {
 croak 'Wrong number of arguments for wizard()' if @_ % 2;
 my %opts = @_;
 my @cbs  = qw/sig data get set len clear free/;
 push @cbs, 'copy'  if MGf_COPY;
 push @cbs, 'dup'   if MGf_DUP;
 push @cbs, 'local' if MGf_LOCAL;
 push @cbs, qw/fetch store exists delete/ if VMG_UVAR;
 my $ret = eval { _wizard(map $opts{$_}, @cbs) };
 if (my $err = $@) {
  $err =~ s/\sat\s+.*?\n//;
  croak $err;
 }
 return $ret;
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

This function associates C<$wiz> magic to the variable supplied, without overwriting any other kind of magic. You can also supply the numeric signature C<$sig> instead of C<$wiz>. It returns true on success or when C<$wiz> magic is already present, C<0> on error, and C<undef> when no magic corresponds to the given signature (in case C<$sig> was supplied). All extra arguments specified after C<$wiz> are passed to the private data constructor. If the variable isn't a hash, any C<uvar> callback of the wizard is safely ignored.

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

The constants L</SIG_MIN>, L</SIG_MAX>, L</SIG_NBR>, L</MGf_COPY>, L</MGf_DUP>, L</MGf_LOCAL> and L</VMG_UVAR> are also only exported on request. They are all exported by the tags C<':consts'> and C<':all'>.

=cut

use base qw/Exporter/;

our @EXPORT         = ();
our %EXPORT_TAGS    = (
 'funcs' =>  [ qw/wizard gensig getsig cast getdata dispell/ ],
 'consts' => [ qw/SIG_MIN SIG_MAX SIG_NBR MGf_COPY MGf_DUP MGf_LOCAL VMG_UVAR/,
               qw/VMG_COMPAT_ARRAY_PUSH_NOLEN VMG_COMPAT_ARRAY_UNSHIFT_NOLEN_VOID VMG_COMPAT_ARRAY_UNDEF_CLEAR/,
               qw/VMG_COMPAT_SCALAR_LENGTH_NOLEN/,
               qw/VMG_PERL_PATCHLEVEL/,
               qw/VMG_THREADSAFE/ ]
);
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

=head1 CAVEATS

If you store a magic object in the private data slot, the magic won't be accessible by L</getdata> since it's not copied by assignation. The only way to address this would be to return a reference.

If you define a wizard with a C<free> callback and cast it on itself, this destructor won't be called because the wizard will be destroyed first.

=head1 DEPENDENCIES

L<perl> 5.7.3.

L<Carp> (standard since perl 5), L<XSLoader> (standard since perl 5.006).

Copy tests need L<Tie::Array> (standard since perl 5.005) and L<Tie::Hash> (since 5.002).

Some uvar tests need L<Hash::Util::FieldHash> (standard since perl 5.009004).

Glob tests need L<Symbol> (standard since perl 5.002).

Threads tests need L<threads> and L<threads::shared>.

=head1 SEE ALSO

L<perlguts> and L<perlapi> for internal information about magic.

L<perltie> and L<overload> for other ways of enhancing objects.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-variable-magic at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Magic>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Variable::Magic

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Variable-Magic>.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Variable::Magic
