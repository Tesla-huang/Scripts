#!/usr/bin/perl

use warnings;
use strict;
use utf8;


open IN,"$ARGV[0]" or die $!;
my $head = <IN>;
while(<IN>) {
	chomp;
	my $species;
	my @tmp = split /\s+/, $_, 2;
	(my $spe) = $tmp[1] =~ /\[(.+)\]/;
	if ($spe =~ /\[/) {
		$species = $';
	}else{
		$species = $spe;
	}
	print "$tmp[0]\t$species\n";
}
