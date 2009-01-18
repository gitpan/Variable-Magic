use 5.007003;

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
   push @DEFINES, '-DVMG_COMPAT_ARRAY_PUSH_NOLEN=1';
  }
 }
}
print $is_as ? "yes\n" : "no\n";

# Threads, Windows and 5.8.x don't seem to be best friends
if ($^O eq 'MSWin32' && $^V lt v5.9.0) {
 push @DEFINES, '-DVMG_MULTIPLICITY=0';
}

@DEFINES = (DEFINE => join ' ', @DEFINES) if @DEFINES;

my $BUILD_REQUIRES = {
 'Config'              => 0,
 'ExtUtils::MakeMaker' => 0,
 'Test::More'          => 0,
};

sub build_req {
 my $tometa = ' >> $(DISTVNAME)/META.yml;';
 my $build_req = 'echo "build_requires:" ' . $tometa;
 foreach my $mod ( sort { lc $a cmp lc $b } keys %$BUILD_REQUIRES ) {
  my $ver = $BUILD_REQUIRES->{$mod};
  $build_req .= sprintf 'echo "    %-30s %s" %s', "$mod:", $ver, $tometa;
 }
 return $build_req;
}

my $RESOURCES = {
 'repository' => 'http://git.profvince.com/perl/modules/Variable-Magic.git',
 'bugtracker' => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Magic',
};

sub resources {
 my $tometa = ' >> $(DISTVNAME)/META.yml;';
 my $build_req = 'echo "resources:" ' . $tometa;
 foreach my $res ( sort { lc $a cmp lc $b } keys %$RESOURCES ) {
  my $val = $RESOURCES->{$res};
  $build_req .= sprintf 'echo "    %-15s %s" %s', "$res:", $val, $tometa;
 }
 return $build_req;
}

WriteMakefile(
    NAME          => 'Variable::Magic',
    AUTHOR        => 'Vincent Pit <perl@profvince.com>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Variable/Magic.pm',
    ABSTRACT_FROM => 'lib/Variable/Magic.pm',
    PL_FILES      => {},
    @DEFINES,
    PREREQ_PM     => {
        'Carp'     => 0,
        'Exporter' => 0,
        'XSLoader' => 0
    },
    dist          => { 
        PREOP      => 'pod2text lib/Variable/Magic.pm > $(DISTVNAME)/README; '
                      . build_req . resources,
        COMPRESS   => 'gzip -9f', SUFFIX => 'gz'
    },
    clean         => { FILES => 'Variable-Magic-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt' },
);
