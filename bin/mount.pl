#!/usr/bin/perl

use strict;
use warnings;
use Tie::Mounted;

#$Tie::Mounted::Only = 1;

my $node = '';

tie my @mounted, 'Tie::Mounted', '-v', $node;
local $, = "\n";
print @mounted; print "\n";
untie @mounted;
