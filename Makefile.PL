use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Tie::Mounted',
    VERSION_FROM => 'lib/Tie/Mounted.pm',
    PREREQ_PM    => { Tie::Array => 0 },
    ($] >= 5.005 
      ? (ABSTRACT_FROM => 'lib/Tie/Mounted.pm') : ()
    ),
);
