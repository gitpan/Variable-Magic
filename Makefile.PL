use 5.008;

use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN {
 eval { require Config };
 die 'OS unsupported' if $@;
 Config->import(qw/%Config/);
}

my @DEFINES;

my $pl = $Config{perl_patchlevel};
print "Checking perl patchlevel... ";
if (defined $pl && length $pl) {
 $pl = int $pl;
 push @DEFINES, '-DVMG_PERL_PATCHLEVEL=' . $pl;
 print $pl, "\n";
} else {
 print "none\n";
}

my $is_as = 0;
print "Checking if this is Windows ActiveState 5.8.[78]... ";
if ($^O eq 'MSWin32' && $^V ge v5.8.7 && $^V lt v5.8.9) {
 eval {
  require Win32;
  1;
 } and do {
  if (defined &Win32::BuildNumber) {
   $is_as = 1;
  }
 }
}
print $is_as ? "yes\n" : "no\n";

# Threads, Windows and 5.8.x don't seem to be best friends
if ($^O eq 'MSWin32' && $^V lt v5.9.0) {
 push @DEFINES, '-DVMG_MULTIPLICITY=0';
}

@DEFINES = (DEFINE => join ' ', @DEFINES) if @DEFINES;

my $dist = 'Variable-Magic';

my %META = (
 configure_requires => {
  'Config'              => 0,
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'Carp'                => 0,
  'Config'              => 0,
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
 },
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/perl/modules/$dist.git",
 },
);

WriteMakefile(
    NAME             => 'Variable::Magic',
    AUTHOR           => 'Vincent Pit <perl@profvince.com>',
    LICENSE          => 'perl',
    VERSION_FROM     => 'lib/Variable/Magic.pm',
    ABSTRACT_FROM    => 'lib/Variable/Magic.pm',
    PL_FILES         => {},
    @DEFINES,
    PREREQ_PM        => {
        'Carp'     => 0,
        'Exporter' => 0,
        'XSLoader' => 0
    },
    MIN_PERL_VERSION => 5.008,
    META_MERGE       => \%META,
    dist             => {
        PREOP    => 'pod2text lib/Variable/Magic.pm > $(DISTVNAME)/README',
        COMPRESS => 'gzip -9f', SUFFIX => 'gz'
    },
    clean            => {
        FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
    },
);
