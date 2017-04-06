#!/usr/bin/perl -w

use strict;

open IN, "$ARGV[0]" or die $!;

local $/ = "\n>";

while (<IN>) {
	chomp;
	s/^\n//;
	s/^>//;
	my @tmp = split /\n/, $_, 2;
	my @id = split /\s+/, $tmp[0];
	$tmp[1] =~ s/\n//g;
	print ">$id[0]\n$tmp[1]\n";
}
