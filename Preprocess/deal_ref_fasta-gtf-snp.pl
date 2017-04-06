#!/usr/bin/env perl
use warnings;
use strict;

die "	perl $0 <fasta> <gtf> <outprefix>
Note:
	make sure you have authority to write into disk
	dealed fasta contain /^[0-9XYxy]+\$/ chrs
	dealed gtf is same to dealed fasta and sorted by start and end
\n" if @ARGV != 3;

my $perl = "/usr/local/bin/perl";
my $java = "/Bio/Software/Java/jdk1.8.0_101/bin/java";
my $samtools = "/Bio/Bin/samtools";
my $gffread = "/Bio/Bin/gffread";
my $picard = "/Bio/Bin/picard.jar";


my ($fa, $gtf, $op) = @ARGV;

if(-s "$op.fa")
{
	print STDERR "fasta is existent\n";
}else{
print STDERR "fasta processing...[1/6]\n";
open FAO, "> $op.fa" or die $!;
$/ = "\n>";
if ($fa =~ /\.gz$/)
{
	open FA, "zcat $fa |" or die $!;
}
else
{
	open FA, $fa or die $!;
}
while(<FA>)
{
	chomp;
	s/^>//;
	my @lines = split /\n/;
	my @c = split /\s+/, $lines[0];
	if($c[0] =~ /^[0-9XYxy]+$/)
	{
		print FAO ">$_\n";
	}
}
$/ = "\n";
}

if(-s "$op.fa.fai")
{
print STDERR "samtools index is existent\n";
}else{
print STDERR "samtools index processing...[2/6]\n";
`$samtools faidx $op.fa`;
}

if(-s "$op.dict" or -s "$op.hdrs")
{
print STDERR "picard index is existent\n";
}else{
print STDERR "picard index processing...[3/6]\n";
`$java -jar $picard CreateSequenceDictionary R=$op.fa O=$op.dict`;
`$perl /Bio/User/linyifan/script/Preprocess/fasta.hdrs.pl $op.fa $op`;
}

my @chrs;
open SFI, "$op.fa.fai" or die $!;
while(<SFI>)
{
	chomp;
	my @t = split;
	push @chrs, $t[0];
}

if(-s "$op.gtf")
{
	print STDERR "gtf is existent\n";
}else{
print STDERR "gtf processing...[4/6]\n";
my (%gse, %bgl);
if ($gtf =~ /\.gz$/)
{
	open GTF, "zcat $gtf |" or die $!;
}
else
{
	open GTF, $gtf or die $!;
}
while(<GTF>)
{
	chomp;
	next if(/^#/);
	my @tmp = split /\t/;
	if($tmp[8] =~ /transcript_biotype "protein_coding";/){
		$bgl{$1} = 0 if($tmp[8] =~ /gene_id "([^;]+)";/);
		push @{$gse{$tmp[0]}{$tmp[3]}{$tmp[4]}}, $_;
	}
}
open BGL, "> $op.bgl" or die $!;
foreach(keys %bgl)
{
	print BGL "$_\n";
}

open GTFO, "> $op.gtf" or die $!;
foreach(@chrs)
{
	foreach my $i(sort {$a<=>$b} keys %{$gse{$_}})
	{
		foreach my $j(sort {$a<=>$b} keys %{$gse{$_}{$i}})
		{
			print GTFO join "\n", @{$gse{$_}{$i}{$j}};
			print GTFO "\n";
		}
	}
}
}

if(-s "$op\_pep.fa")
{
	print STDERR "pep.fa is existent\n";
}else{
	print STDERR "gtf to pep processing...[5/6]\n";
	`$gffread $op.gtf -g $op.fa -x $op\_cds.fa`;
	`$perl /Bio/User/linyifan/script/Preprocess/cds2pep.pl $op\_cds.fa $op\_pep.fa`;
}

if(-s "${op}_refGene.txt" or -s "${op}_refGeneMrna.fa")
{
print STDERR "2refGene is existent\n";
}else{
print STDERR "gtf to genepred processing...[6/6]\n";
#`gffread $op.gtf -o $op.gff`;
#`sed -i 1d $op.gff`;
`/Bio/User/linyifan/script/Preprocess/gtfToGenePred -genePredExt $op.gtf $op.genepred`;
`awk '{print 1"\t"\$0}' $op.genepred > ${op}_refGene.txt`;
`$perl /Bio/User/linyifan/script/Preprocess/retrieve_seq_from_fasta.pl -format refGene -seqfile $op.fa --outfile ${op}_refGeneMrna.fa ${op}_refGene.txt`;
}

print STDERR "all done!\n";
