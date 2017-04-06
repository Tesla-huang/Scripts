#! /usr/bin/perl

use utf8;
use strict;
use lib "/home/linyifan/bio/perl5lib/blib/lib";
use Statistics::RankCorrelation;
use warnings;
use Getopt::Long;
#use Bio::SeqIO;
#use Bio::Seq;
#use List::Util qw/sum min max/;
#use List::MoreUtils qw/uniq/;
#use File::Basename qw/basename dirname/;
#use File::Spec::Functions qw/rel2abs/;
#use FindBin qw/$Bin $Script/;

die "perl $0 <miRNA.TPM.exp> <RNAseq.rpkm/fpkm.matrix> <target_index_annot.xls>\n" unless(@ARGV eq 3);

open IN1, "$ARGV[0]" or die $!;
open IN2, "$ARGV[1]" or die $!;
my (%hash1, %hash2);

while(<IN1>){
	chomp;
	my @line = split /\t/;
	my $id = shift(@line);
	$hash1{$id} = \@line;
}
while(<IN2>){
	chomp;
	my @line = split /\t/;
	my $id = shift(@line);
	$hash2{$id} = \@line;
}
close IN2;
close IN1;

#print "query_A\tquery_B\tRankCorrelation\n";
#foreach my $a (keys %hash1){
#	foreach my $b (keys %hash2){
#	my $cs = Statistics::RankCorrelation->new($hash1{$a}, $hash2{$b});
#	my $s = $cs->spearman;
#	print "$a\t$b\t$s\n";
#	}
#}

open IN, "$ARGV[2]" or die $!;
my $head = <IN>;
chomp($head);
my @head = split /\t/, $head;
splice(@head,2,0,"rho");
$head = join("\t", @head);
print "$head\n";
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	my $mirid = $tmp[0];
	my $geneid = $tmp[1];
	if (exists $hash1{$mirid} && exists $hash2{$geneid}) {
		my $cs = Statistics::RankCorrelation->new($hash1{$mirid}, $hash2{$geneid});
		my $s = $cs->spearman;
		splice(@tmp,2,0,$s);
	}else{
		splice(@tmp,2,0,"Null");
	}
	my $text = join("\t",@tmp);
	print "$text\n";
}
close IN;
