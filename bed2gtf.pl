#!/usr/bin/perl -w

use strict;
use utf8;


open IN, "$ARGV[0]" or die $!;
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	my $chr = $tmp[0]; $chr =~ s/chr//i;
	my $start = $tmp[1];
	my $id = $tmp[3];
	my $strand = $tmp[5];
	my @bsize = split /,/, $tmp[10];
	my @bstart = split /,/, $tmp[11];
	for (my $i = 0; $i < scalar(@bsize); $i++) {
		my $beg = $start + $bstart[$i] + 1;
		my $end = $beg + $bsize[$i] - 1;
		print "$chr\tIvan\texon\t$beg\t$end\t.\t$strand\t.\ttranscript_id \"$id\"\;\n";
	}
}

