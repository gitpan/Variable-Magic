package Variable::Magic::TestThreads;

use strict;
use warnings;

use Config qw<%Config>;

use Variable::Magic qw<VMG_THREADSAFE>;

sub skipall {
 my ($msg) = @_;
 require Test::More;
 Test::More::plan(skip_all => $msg);
}

sub diag {
 require Test::More;
 Test::More::diag(@_);
}

sub import {
 shift;

 skipall 'This Variable::Magic isn\'t thread safe' unless VMG_THREADSAFE;

 my $force = $ENV{PERL_VARIABLE_MAGIC_TEST_THREADS} ? 1 : !1;
 skipall 'This perl wasn\'t built to support threads'
                                                    unless $Config{useithreads};
 skipall 'perl 5.13.4 required to test thread safety'
                                              unless $force or "$]" >= 5.013004;

 my $t_v = $force ? '0' : '1.67';
 my $has_threads =  do {
  local $@;
  eval "use threads $t_v; 1";
 };
 skipall "threads $t_v required to test thread safety" unless $has_threads;

 my $ts_v = $force ? '0' : '1.14';
 my $has_threads_shared =  do {
  local $@;
  eval "use threads::shared $ts_v; 1";
 };
 skipall "threads::shared $ts_v required to test thread safety"
                                                     unless $has_threads_shared;

 defined and diag "Using threads $_"         for $threads::VERSION;
 defined and diag "Using threads::shared $_" for $threads::shared::VERSION;

 my %exports = (
  spawn => \&spawn,
 );

 my $pkg = caller;
 while (my ($name, $code) = each %exports) {
  no strict 'refs';
  *{$pkg.'::'.$name} = $code;
 }
}

sub spawn {
 local $@;
 my @diag;
 my $thread = eval {
  local $SIG{__WARN__} = sub { push @diag, "Thread creation warning: @_" };
  threads->create(@_);
 };
 push @diag, "Thread creation error: $@" if $@;
 if (@diag) {
  require Test::More;
  Test::More::diag($_) for @diag;
 }
 return $thread ? $thread : ();
}

1;
