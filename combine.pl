#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <tp> <mirud> <lncud>\nstdout\n" if (@ARGV != 3);

my %mir;
open IN, "$ARGV[1]" or die $!;
<IN>;
while(<IN>) {
	chomp;
	my @tmp = split /\t/, $_, 2;
	$mir{$tmp[0]} = $tmp[1];
}
close IN;

my %lnc;
open IN, "$ARGV[2]" or die $!;
<IN>;
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_, 2;
	$lnc{$tmp[0]} = $tmp[1];
}
close IN;

open IN, "$ARGV[0]" or die $!;
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	if (exists $mir{$tmp[0]} && exists $lnc{$tmp[1]}) {
		print "$tmp[0]\t$mir{$tmp[0]}\t$tmp[1]\t$lnc{$tmp[1]}\n";
	}
}
