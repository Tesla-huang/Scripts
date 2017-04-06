#! /usr/bin/perl
use strict;
use warnings;
use File::Spec::Functions qw(rel2abs);

die "perl $0 <go file> <kegg file> <outprefix> <species[animal|plant]> <GTF> <g|e|s>
go file 5 cols from biomart: Ensembl Gene ID \\t Entrez ID \\t Associated Gene Name \\t GOSlim GOA Accession(s) \\t Description
g|e|s: kegg file contain GeneID(g: /\\w+/) or EntrezID(e: /\\d+/ or SymbolID(s: /\\w+/))
GTF just for lncRNA mode!~
" unless @ARGV == 6;

open GO, $ARGV[0] or die $!;
open TMP, "> $ARGV[2].tmp" or die $!;
<GO>;
while(<GO>)
{
	$_ =~ s/\t\t/\t0\t/g;
	$_ =~ s/\t\t/\t0\t/g;
	$_ =~ s/\t\t/\t0\t/g;
	$_ =~ s/\t$/\t0/g;
	print TMP $_;
}
close GO;
close TMP;

open GTF, $ARGV[4] or die $!;
my (%gt, %uniq);
while(<GTF>)
{
	if(my ($a) = /gene_id "([^;]+)";/ and my ($b) = /transcript_id "([^;]+)";/)
	{
		if(exists $uniq{$a.$b})
		{
			next;
		}else{
			push @{$gt{$a}}, $b;
			$uniq{$a.$b} = 0;
		}
	}
}
close GTF;

my $gs = 0;
if($ARGV[5] eq "g")
{
	$gs = 0;
}elsif($ARGV[5] eq "e"){
	$gs = 1;
}elsif($ARGV[5] eq "s"){
	$gs = 2;
}

my (%g2go, %g2sb, %g2ds, %hash);
open TMP, "$ARGV[2].tmp" or die $!;
while(<TMP>)
{
	chomp;
	my @tmp = split /\t/;
	if (!exists $gt{$tmp[0]}) 
	{
		next;
	}else{
	if($tmp[3] ne 0)
	{
		$g2go{"$tmp[0]\t$tmp[3]"} = 0;
	}else{
		$g2go{"$tmp[0]\t-"} = 0;
	}
	if($tmp[2] ne 0)
	{
		$g2sb{"$tmp[0]\t$tmp[2]"} = 0;
	}else{
		$g2sb{"$tmp[0]\t-"} = 0;
	}
	if($tmp[4] ne 0)
	{
		$g2ds{"$tmp[0]\t$tmp[4]"} = 0;
	}else{
		$g2ds{"$tmp[0]\t-"} = 0;
	}
	if($tmp[$gs] ne 0)
	{
		push @{$hash{$tmp[$gs]}}, @{$gt{$tmp[0]}};
	}
	}
}
close TMP;
`rm $ARGV[2].tmp -rf`;

my $outdir = "$ARGV[2]\_annot";
system "mkdir $outdir";
open GT, "> $outdir/$ARGV[2].annot" or die $!;
open GS, "> $outdir/$ARGV[2].gen2sym" or die $!;
open GD, "> $outdir/$ARGV[2].desc" or die $!;
foreach(keys %g2go)
{
	my ($g, $o) = split;
	foreach my $i(@{$gt{$g}})
	{
		print GT "$i\t$o\n";
	}
}
foreach(keys %g2sb)
{
	my ($g, $o) = split;
	foreach my $i(@{$gt{$g}})
	{
		print GS "$i\t$o\n";
	}
}
foreach(keys %g2ds)
{
	my ($g, $o) = split /\t/;
	foreach my $i(@{$gt{$g}})
	{
		print GD "$i\t$o\n";
	}
}

chdir "$outdir";
`perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/annot2goa.pl $ARGV[2].annot $ARGV[2]`;
`perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/annot2wego.pl -i $ARGV[2].annot -o $ARGV[2].wego`;
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].P > $ARGV[2].rc.P";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].F > $ARGV[2].rc.F";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].C > $ARGV[2].rc.C";
chdir "..";

my $s;
if($ARGV[3] eq "animal")
{
	$s = "/Bio/Database/Database/kegg/data/map_class/animal_ko_map.tab";
}elsif($ARGV[3] eq "plant"){
	$s = "/Bio/Database/Database/kegg/data/map_class/plant_ko_map.tab";
}else{
	die "species: animal or plant!";
}

open KEGG, ($ARGV[1] =~ /.*\.gz/) ? "gzip -dc $ARGV[1] |" : $ARGV[1] or die $!;
my (%ko, %bko);
my $bp;
while(<KEGG>)
{
	if(/^B\s+<b>(.*)<\/b>/){
		$bp = $1;
	}
	if(/^D/)
	{
		my @tmp = split /\t/;
		next if(@tmp < 2);
		my ($a, $b) = (split /\s+/, $tmp[0])[1,2];
		my $x;
		if($gs == 0 || $gs == 2)
		{
			$x = uc($b);
		}elsif($gs == 1){
			$x = $a;
		}
		if(exists $hash{$x})
		{
			my @k = split /\s+/, $tmp[1];
			foreach my $t(@{$hash{$x}})
			{
				$ko{$t}{$k[0]} = 0;
				$bko{$t}{$bp} = 0;
			}
		}
	}
}

open KT, "> $outdir/$ARGV[2].ko" or die $!;
my %bko2;
foreach(keys %ko)
{
	foreach my $i(keys %{$ko{$_}})
	{
		print KT "$_\t$i\n";
	}
	foreach my $i(keys %{$bko{$_}})
	{
		$bko2{$_} .= "$i;";
	}
	$bko2{$_} =~ s/;$//;
}

`perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/pathfind.pl -fg $outdir/$ARGV[2].ko -komap $s -out $outdir/$ARGV[2].path`;
`perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/genDesc.pl -gene2tr $outdir/$ARGV[2].gen2sym -desc $outdir/$ARGV[2].desc -pathway $outdir/$ARGV[2].path -go $outdir/$ARGV[2] -output $outdir/$ARGV[2].Annot.tmp`;

open AAA, "$outdir/$ARGV[2].Annot.tmp" or die $!;
<AAA>;
open FO, ">$outdir/$ARGV[2].Annot.txt" or die $!;
print FO "GeneID\tSymbol\tDescription\tB class Pathway\tC class Pathway\tGO Component\tGO Function\tGO Process\n";
while(<AAA>)
{
	chomp;
	my @tmp = split /\t/;
	if(exists $bko2{$tmp[0]})
	{
		print FO join("\t", @tmp[0..2], $bko2{$tmp[0]}, @tmp[3..$#tmp])."\n";
	}else{
		print FO join("\t", @tmp[0..2], "-", @tmp[3..$#tmp])."\n";
	}
}

my $out = rel2abs($outdir);
`/bin/sed 's#^dir=#dir=$out#' /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/gokegg.sh > $out/gokegg.sh`;
`/bin/sed -i 's#^wego=#wego=$out/$ARGV[2]\.wego#' $out/gokegg.sh`;
`/bin/sed -i 's#^ko=#ko=$out/$ARGV[2]\.ko#' $out/gokegg.sh`;
`/bin/sed -i 's#^komap=#komap=$s#' $out/gokegg.sh`;
`/bin/sed -i 's#^go=#go=$out/#' $out/gokegg.sh`;
`/bin/sed -i 's#^go_species=#go_species=$ARGV[2]#' $out/gokegg.sh`;
