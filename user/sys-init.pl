#!/usr/bin/perl -w

die 'pls run as root ' if ($> != 0);

use strict;
use Linux::Distribution qw(distribution_name distribution_version);

my $linux = Linux::Distribution->new;
die 'known Linux' if (not $linux);

print $linux->distribution_version."\n";
