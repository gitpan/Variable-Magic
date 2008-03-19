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
 push @DEFINES, DEFINE => '-DVMG_PERL_PATCHLEVEL=' . $pl;
 print $pl, "\n";
} else {
 print "none\n";
}

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
                      . build_req,
        COMPRESS   => 'gzip -9f', SUFFIX => 'gz'
    },
    clean         => { FILES => 'Variable-Magic-* *.gcov *.gcda *.gcno cover_db' },
);
