use ExtUtils::MakeMaker;
WriteMakefile(
    DISTNAME     => 'Tie-Mounted',
    NAME         => 'Tie::Mounted',
    VERSION_FROM => 'lib/Tie/Mounted.pm',
    PREREQ_PM    => { Tie::Array => 0 },
    'dist'       => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    ($] >= 5.005 
      ? (ABSTRACT_FROM => 'lib/Tie/Mounted.pm') : ()
    ),
);
