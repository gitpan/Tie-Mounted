#!/usr/bin/perl

use strict;
use warnings;
use Tie::Mounted;

#$Tie::Mounted::No_files = 1;

my $node = '';

tie my @mounted, 'Tie::Mounted', $node, '-v';
$, = "\n";
print @mounted; print "\n";
untie @mounted;
