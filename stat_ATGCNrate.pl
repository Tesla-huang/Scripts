#!/usr/bin/perl -w 

use strict;

local $/ = "\n>";
open IN, "$ARGV[0]" or die $!;
while (<IN>) {
	chomp;
	s/>//;
	my @tmp = split /\n/, $_, 2;
	my $seq = $tmp[1];
	$seq =~ s/\n//g;
	$seq =~ tr/atgcn/ATGCN/;
	my $len = length($seq);
	my $as = $seq =~ tr/A/A/;
	my $arate = $as/$len;
	my $ts = $seq =~ tr/T/T/;
	my $trate = $ts/$len;
	my $gs = $seq =~ tr/G/G/;
	my $grate = $gs/$len;
	my $cs = $seq =~ tr/C/C/;
	my $crate = $cs/$len;
	my $ns = $seq =~ tr/N/N/;
	my $nrate = $ns/$len;
	print ">$tmp[0]\t$len\tA:$arate\tT:$trate\tG:$grate\tC:$crate\tN:$nrate\n$seq\n";
}
