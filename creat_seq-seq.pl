#!/usr/bin/perl -w

use strict;

open FA, "$ARGV[0]" or die $!;
open FB, "$ARGV[1]" or die $!;

my %seq;

local $/ = "\n>";
while (<FA>) {
	chomp;
	s/^\n//;
	s/^>//;
	$seq{$.} = $_;
}

while (<FB>) {
	chomp;
	s/^\n//;
	s/^>//;
	foreach my $i (sort keys %seq) {
		print ">$seq{$i}\n>$_\n";
	}
}
