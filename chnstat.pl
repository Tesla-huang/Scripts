#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <RNAplex.aln> <window_size> <subject_length>\n" if (@ARGV != 3);
open IN, "$ARGV[0]" or die $!;
my $window = $ARGV[1];
my $ref = $ARGV[2];

local $/ = "\n\n";

my %hash;
my $min = 0;
open OUT, "> $ARGV[0].stat" or die $!;
print OUT "query\tsubject\tquery_start\tquery_end\tsubject_start\tsubject_end\tfree_energy\n";
while(<IN>) {
	chomp;
	my @tmp = split /\n/, $_;
	my $query = shift(@tmp);
	$query =~ /(\d+)-(\d+)$/;
	my $qs = $1;
	my $qe = $2;
	my $subject = shift(@tmp);
	foreach my $i (@tmp) {
		my @info = split /\s+/, $i;
		$info[1] =~ /(\d+),(\d+)/;
		my $s = $1 + $qs - 1;
		my $e = $2 + $qs - 1;
		$info[3] =~ /(\d+),(\d+)/;
		my $rs = $1;
		my $re = $2;
		my ($fe) = $info[4] =~ /\((\S+)\)/;
		$min = $fe if ($min > $fe);
		$hash{$rs}{$s} = $fe; ##$hash{subject_start}{query_start} = free_energy
		print OUT "$query\t$subject\t$s\t$e\t$rs\t$re\t$fe\n";
	}
}
close IN;
close OUT;
print "$min\n";
my %matrix;
my $step_x = 0;
foreach my $i (keys %hash) {
	my $scalar = int($i/$window);
	foreach my $j (keys %{$hash{$i}}){
		my $step = int($j/$window);
		$step_x = $step if ($step > $step_x);
		if (!exists $matrix{$scalar}{$step}) {
			$matrix{$scalar}{$step} = $hash{$i}{$j};
		}elsif ($matrix{$scalar}{$step} > $hash{$i}{$j}) {
			$matrix{$scalar}{$step} = $hash{$i}{$j};
		}
	}
}
open MAT, "> $ARGV[0].mat" or die $!;
print MAT "Distence";
for (my $dis = 0; $dis < $step_x + 1; $dis++) {
	my $start = $dis*$window;
	print MAT "\t$start";
}
print MAT "\n";
foreach my $i (sort {$a <=> $b} keys %matrix) {
	my $sub_dis = ($i + 1)*$window - $ref;
	print MAT "$sub_dis";
	for (my $j = 0; $j < $step_x + 1; $j++){
		if (!exists $matrix{$i}{$j}){
			print MAT "\t0";
		}else{
			print MAT "\t$matrix{$i}{$j}";
		}
	}
	print MAT "\n";
}
close MAT;
