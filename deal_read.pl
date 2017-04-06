#!/usr/bin/perl -w

use strict;

open IN, "gzip -dc $ARGV[0]|" or die $!;
open OUT, "> $ARGV[1]" or die $!;

while (<IN>) {
	chomp;
	if (/^@/) {
		$_ =~ s/\/1$//;
		print OUT "$_\n";
	}else{
		print OUT "$_\n";
	}
}
