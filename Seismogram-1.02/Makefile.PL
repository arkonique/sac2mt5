use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Seismogram',
    AUTHOR              => 'Craig Scrivner <scrivner@geology.cwu.edu>',
    VERSION_FROM        => 'lib/Seismogram/SAC.pm',
    ABSTRACT_FROM       => 'lib/Seismogram/SAC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TauP-*' },
);
