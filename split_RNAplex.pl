#!/usr/bin/perl -w

use strict;
use utf8;

open IN, "$ARGV[0]" or die $!;
local $/ = "\n\n";
while (<IN>) {
	chomp;
	s/>//g;
	my @tmp = split /\n/, $_;
	my $query = shift(@tmp);
	my $ref = shift(@tmp);
	my $file = "$query\_$ref.xls";
	my $pair = "#Query:$query\tRef:$ref\n";
	my $head = "Query_Start\tQuery_End\t:\tRef_Start\tRef_End\tfree_energy\tnucleotide_pairings\n";
	open OUT, "> $file" or die $!;
	print OUT $pair;
	print OUT $head;
	foreach my $i (@tmp) {
		my @info = split /\s+/, $i;
		my @text;
		$info[1] =~ /(\d+),(\d+)/;
		push @text, $1,$2,$info[2];
		$info[3] =~ /(\d+),(\d+)/;
		push @text, $1,$2;
		$info[4] =~ /\((\S+)\)/;
		push @text, $1,$info[0];
		print OUT join("\t",@text);
		print OUT "\n";
	}
	close OUT;
}
