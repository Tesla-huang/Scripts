#! usr/bin/perl

use strict;
use warnings;

my $file1=shift;### mRNA database fasta ###
#my $file2=shift;### lncRNA database fasta ###
my $file3=shift;### RNAplex output ###
my $file4=shift;### out file ###
my (%hash);

$/="\>";
open IN,$file1;
#open IN1,$file2;
#open IN2,$file3;
#open OUT,">$file4";

#$/="\>";
<IN>;
while (<IN>){
#	chomp;
#	my $mRNA=$_;
#	my @array=split /\s+/,$mRNA;
#	my $seq=<IN>;
#	chomp($seq);
#	$hash{$array[0]}=$seq;
	my $id;
	s/>//;
	my @a=split(/\n/,$_);
	my $head=shift @a;
	if ($head=~/(\S+)/)	{$id="\>$1"}
	$hash{$id}=join "",@a;

}
#<IN1>;
#while (<IN1>){
#	chomp;
#	my $lncRNA=$_;
#	my @array=split /\s+/,$lncRNA;
#	my $seq=<IN1>;
#	chomp($seq);
#	$hash{$array[0]}=$seq;
#	my $id;
#	s/>//;
#       my @a=split(/\n/,$_);
#       my $head=shift @a;
#       if ($head=~/(\S+)/)    {$id="\>$1"}
#   $hash{$id}=join "",@a;	
#}

#foreach (keys %hash)
#{
#print "\>$_\n$hash{$_}\n"
#}

$/="\n\n";
open IN2,$file3;
open OUT,">$file4";
while (<IN2>){
	chomp;
	my @tmp = split /\n/, $_;
	my $lncRNA=shift(@tmp);
	my $mRNA=shift(@tmp);
	my $info = pop(@tmp);
	my @array=split /\s+/,$info;
	my @mRNAsite=split /,/, $array[3];
	my @lncRNAsi=split /,/, $array[1];
	my $mRNAseq=substr($hash{$mRNA},$mRNAsite[0]-1,$mRNAsite[1]-$mRNAsite[0]+1);
	my $lncRNAseq=substr($hash{$lncRNA},$lncRNAsi[0]-1,$lncRNAsi[1]-$lncRNAsi[0]+1);
	my $seq="$lncRNAseq&$mRNAseq";
	$seq=~tr/atcg/ATCG/;
	my $align = shift(@array);
	print OUT"$lncRNA\n$mRNA\t@array\n$seq\n$align\n\n";
}
