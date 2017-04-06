#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <tfbs> <gtf> \noutput:<tfbs>.annot.xls\n" if (@ARGV != 2);
open IN, "$ARGV[0]" or die $!;
open GTF, "$ARGV[1]" or die $!;

my (%hash, %start, %end, %strand, %type);

while (<GTF>) {
	chomp;
	my @tmp = split /\t/, $_;
	my $c = $tmp[0];##chr
	my $t = $tmp[2];##type
	my $s = $tmp[3];##start
	my $e = $tmp[4];##end
	my $d = $tmp[6];##strand
	my ($id) = $tmp[8] =~ /gene_id "(\S+)";/;##gene_id
	push @{$hash{$c}{$id}{$t}}, $s, $e;
	$strand{$id} = $d;
}

foreach my $c (keys %hash){
	foreach my $id (keys %{$hash{$c}}) {
		my @tmp = sort {$a <=> $b} @{$hash{$c}{$id}{"exon"}};
		my $s = $tmp[0];
		my $e = $tmp[$#tmp];
		$start{$c}{$id} = $s;
		$end{$c}{$id} = $e;
	}
}

open OUT, "> $ARGV[0].annot.xls" or die $!;
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	my $c = $tmp[0];
	my $s = $tmp[3];
	my $e = $tmp[4];
	my $pos = int(($s + $e)/2);
	my $in;
	my $up;
	my $down;
	foreach my $id (sort {$start{$c}{$a} <=> $start{$c}{$b}} keys %{$start{$c}}){
		if ($pos >= $start{$c}{$id}) {
			if ($pos <= $end{$c}{$id}) {
				$in = $id;
				last;
			}else{
				$up = $id;
			}
		}else{
			$down = $id;
			last;
		}
	}
	if (defined $in) {
		my %site;
		if (exists $hash{$c}{$in}{"exon"}) {
			my @exon = @{$hash{$c}{$in}{"exon"}};
			for (my $i = 0; $i < (scalar(@exon))/2 + 1; $i++) {
				my $sx = shift(@exon);
				my $ex = shift(@exon);
				foreach my $x ($sx..$ex) {
					$site{$x} = 0;
				}
			}
		}
		if (exists $hash{$c}{$in}{"CDS"}) {
			my @CDS = @{$hash{$c}{$in}{"CDS"}};
			for (my $i = 0; $i < (scalar(@CDS))/2 + 1; $i++) {
				my $sx = shift(@CDS);
				my $ex = shift(@CDS);
				foreach my $x ($sx..$ex) {
					$site{$x} += 1;
				}
			}
		}
		my $region;
		if (!exists $site{$pos}) {
			$region = "intron";
		}elsif($site{$pos} == 1) {
			$region = "CDS";
		}else{
			$region = "UTR";
		}
		print OUT "$_\t$region\t$in $start{$c}{$in} $end{$c}{$in} $strand{$in}\n";
	}else{
		print OUT "$_\tintergenic";
		if (defined $up) {
			my $distence = $s - $end{$c}{$up};
			print OUT "\tUP $distence : $up $start{$c}{$up} $end{$c}{$up} $strand{$up}";
		}
		if (defined $down) {
			my $distence = $start{$c}{$down} - $e;
			print OUT "\tDOWN $distence : $down $start{$c}{$down} $end{$c}{$down} $strand{$down}";
		}
		print OUT "\n";
	}
}

