#!/usr/bin/perl -w

use strict;
use utf8;

open IN, "$ARGV[0]" or die $!;
open OUT, "> $ARGV[0].ko" or die $!;
<IN>;
while(<IN>) {
	chomp;
	my @tmp = split /\s+/, $_;
	my $id = $tmp[0];
	my @go = grep {/K\d{5}/} @tmp;
	for my $i (0..$#go){
		my ($tmp) = $go[$i] =~ /(K\d{5})/;
		$go[$i] = $tmp;
	}
	my %hash;
	@go = grep { ++$hash{$_} < 2 } @go;
	print OUT join("\t",$id,@go)."\n";
}
