#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <tr2gene> <cds.fa>\nlongest.tr2gene\n" if (@ARGV != 2);

open IN, "$ARGV[0]" or die $!;
my %hash;
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	$hash{$tmp[0]} = $tmp[1];
}

open FA, "$ARGV[1]" or die $!;
local $/ = "\n>";
my %len;
while (<FA>) {
	chomp;
	s/^>//;
	my @tmp = split /\n/, $_, 2;
	my $trans_id = (split /\s+/, $tmp[0])[0];
	my $seq = $tmp[1];
	$seq =~ s/\n//g;
	my $len = length($seq);
	$len{$trans_id} = $len;
}

my %most;
my %pair;
foreach my $i (keys %len) {
	if (!exists $most{$hash{$i}} || $len{$i} > $most{$hash{$i}}) {
		$most{$hash{$i}} = $len{$i};
		$pair{$hash{$i}} = $i;
	}
}

open OUT, "> longest.tr2gene" or die $!;
foreach my $i (sort keys %pair) {
	print OUT "$pair{$i}\t$i\n";
}
