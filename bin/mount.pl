#!/usr/local/bin/perl

use strict;
use warnings;
use Tie::Mounted;

#$Tie::Mounted::No_files = 1;

my $node = '';

tie my @files, 'Tie::Mounted', $node, '-v';
$, = "\n";
print @files; print "\n";
untie @files;
