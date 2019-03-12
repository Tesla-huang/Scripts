#!/usr/bin/perl -w

use strict;
use utf8;

die "Usage: perl $0 <table> stdout: table.go\n" if (@ARGV != 1);

open IN, "$ARGV[0]" or die $!;
open OUT, "> $ARGV[0].go" or die $!;
<IN>;
while(<IN>) {
	chomp;
	my @tmp = split /\s+/, $_;
	my $id = $tmp[0];
	my @go = grep {/GO:\d{7}/} @tmp;
	for my $i (0..$#go){
		my ($tmp) = $go[$i] =~ /(GO:\d{7})/;
		$go[$i] = $tmp;
	}
	my %hash;
	@go = grep { ++$hash{$_} < 2 } @go;
	print OUT join("\t",$id,@go)."\n";
}
