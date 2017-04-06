#! /usr/bin/perl

use utf8;
use strict;
use warnings;
#use Getopt::Long;
#use Bio::SeqIO;
#use Bio::Seq;
#use List::Util qw/sum min max/;
#use List::MoreUtils qw/uniq/;
#use File::Basename qw/basename dirname/;
#use File::Spec::Functions qw/rel2abs/;
#use FindBin qw/$Bin $Script/;
#use lib $Bin;

die "perl $0 <gtf> <outpre>\n" unless(@ARGV eq 2);

open GTF, "$ARGV[0]" or die $!;
my %hash;
while (<GTF>) {
	my @tmp = split /\t/, $_;
	if ($tmp[2] eq "exon") {
		die "start pos greater than end pos, please check the gtf file , error line in GTF is $.i\n" if ($tmp[3] > $tmp[4]);
		my ($gene_id) = $tmp[8] =~ /gene_id "(\S+)";/;
		my ($trans_id) = $tmp[8] =~ /transcript_id "(\S+)";/;
		my $length = $tmp[4] - $tmp[3];
		if (!exists $hash{$gene_id}{$trans_id}) {
			$hash{$gene_id}{$trans_id} = $length;
		}else{
			$hash{$gene_id}{$trans_id} += $length;
		}
	}
}
close GTF;

open OUT, "> $ARGV[1].xls" or die $!;
open LIST, "> $ARGV[1].gene2tr" or die $!;
foreach my $i (sort keys %hash) {
	my $best = 0;
	foreach my $j (sort { $hash{$i}{$b} <=> $hash{$i}{$a} } keys %{$hash{$i}}) {
		print OUT "$i\t$j\t$hash{$i}{$j}\n";
		print LIST "$i\t$hash{$i}{$j}\t$j\n" if ($best == 0);
		$best = 1 if ($best == 0);
	}
}
close OUT;
close LIST;
