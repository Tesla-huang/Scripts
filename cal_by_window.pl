#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <RNAplex_TSV> <region> <len>\nstdout\n" if (@ARGV != 3);
my $region = $ARGV[1];
my $len = $ARGV[2];
open IN, "$ARGV[0]" or die $!;
<IN>;
<IN>;
my %hash;
while (<IN>) {
	my @tmp = split /\s+/, $_;
	my $pos = $tmp[0];
	my $energy = $tmp[5];
	my $key = int($pos/$region);
	if (!exists $hash{$key}) {
		$hash{$key} = $energy;
	}elsif ($hash{$key > $energy}){
		$hash{$key} = $energy;
	}
}

my $last = int($len/$region);
for (my $i = 0; $i < $last; $i ++) {
	my $s = $i * $region + 1;
	my $e = ($i + 1) * $region;
	if (!exists $hash{$i}) {
		print "$s\t$e\t0\n";
	}else{
		print "$s\t$e\t$hash{$i}\n";
	}
}
my $s = $last * $region + 1;
my $e = $len;
if (!exists $hash{$last}) {
	print "$s\t$e\t0\n";
}else{
	print "$s\t$e\t$hash{$last}\n";
}
