## Created by make2build 0.17

use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Tie::Mounted',
   dist_version_from => 'lib/Tie/Mounted.pm',
   requires => {
                 'Tie::Array' => 0,
               },
   recommends => {},
   build_requires => {},
   conflicts => {},
   license => 'unknown',
   create_makefile_pl => 'passthrough',
  );
  
$b->create_build_script;
