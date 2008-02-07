use 5.007003;

use strict;
use warnings;
use ExtUtils::MakeMaker;

eval {
 require Config;
};
die "OS unsupported" if $@;

my @DEFINES;

my $pl = $Config::Config{perl_patchlevel};
print "Checking perl patchlevel... ";
if (defined $pl && length $pl) {
 $pl = int $pl;
 push @DEFINES, DEFINE => '-DVMG_PERL_PATCHLEVEL=' . $pl;
 print $pl, "\n";
} else {
 print "none\n";
}

WriteMakefile(
    NAME                => 'Variable::Magic',
    AUTHOR              => 'Vincent Pit <perl@profvince.com>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Variable/Magic.pm',
    ABSTRACT_FROM       => 'lib/Variable/Magic.pm',
    PL_FILES            => {},
    @DEFINES,
    PREREQ_PM => {
        'Carp'       => 0,
        'Exporter'   => 0,
        'Test::More' => 0,
        'XSLoader'   => 0
    },
    dist                => { 
        PREOP => 'pod2text lib/Variable/Magic.pm > $(DISTVNAME)/README',
        COMPRESS => 'gzip -9f', SUFFIX => 'gz'
    },
    clean               => { FILES => 'Variable-Magic-*' },
);
