#!/usr/bin/env perl
use warnings;
use strict;
use File::Spec::Functions qw(rel2abs);

die "perl $0 <go file> <kegg file> <outprefix> <species[animal|plant]> <g|e>
go file 5 cols from biomart: Ensembl Gene ID \\t Entrez ID \\t Associated Gene Name \\t GOSlim GOA Accession(s) \\t Description
g|e: kegg file contain GeneID(g: /\\w+/) or EntrezID(e: /\\d+/)
" unless @ARGV == 5;

my $s;
if($ARGV[3] eq "animal")
{
	$s = "/Bio/Database/Database/kegg/data/map_class/animal_ko_map.tab";
}elsif($ARGV[3] eq "plant"){
	$s = "/Bio/Database/Database/kegg/data/map_class/plant_ko_map.tab";
}else{
	die "species: animal or plant!";
}

my (%hash, %ts);
open GO, (($ARGV[0] =~ /.*\.gz/) ? "gzip -dc $ARGV[0] |" : $ARGV[0]) or die $!;
<GO>;
my $ourdir = "$ARGV[2]\_annot";
system "mkdir $ourdir";
open GT, "> $ourdir/$ARGV[2].annot" or die $!;
open GS, "> $ourdir/$ARGV[2].gen2sym" or die $!;
my %g2s;
my $x = 0;
if($ARGV[4] eq "g")
{
	$x = 0;
}elsif($ARGV[4] eq "e"){
	$x = 1;
}
while(<GO>)
{
	chomp;
	my @tmp = split /\t/;
	if(defined $tmp[2])
	{
		$g2s{$tmp[0]}{$tmp[2]} = 0;
	}else{
		$g2s{$tmp[0]}{'-'} = 0;
	}
	print GT "$tmp[0]\t$tmp[3]\n" if(defined $tmp[3] and $tmp[3] =~ /^GO:/);
	if(defined $tmp[3] and $tmp[3] =~ /^GO:/ and defined $tmp[4])
	{
		$ts{"$tmp[0]\t$tmp[4]"} = 0;
	}elsif(defined $tmp[3] and $tmp[3] =~ /^GO:/ and !defined $tmp[4]){
		
	}elsif(defined $tmp[3] and $tmp[3] !~ /^GO:/){
		$ts{"$tmp[0]\t$tmp[3]"} = 0;
	}else{
		
	}
	next if(!defined $tmp[2]);
	if(exists $hash{$tmp[$x]})
	{
		push @{$hash{$tmp[$x]}}, $tmp[0];
	}else{
		@{$hash{$tmp[$x]}} = ();
	}
}
close GO;
close GT;
foreach(keys %g2s)
{
	foreach my $i(keys %{$g2s{$_}})
	{
		print GS "$_\t$i\n";
	}
}

open DESC, "> $ourdir/$ARGV[2].desc" or die $!;
foreach my $t(keys %ts)
{
	print DESC "$t\n";
}

chdir "$ourdir";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/annot2goa.pl $ARGV[2].annot $ARGV[2]";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/annot2wego.pl -i $ARGV[2].annot -o $ARGV[2].wego";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].P > $ARGV[2].rc.P";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].F > $ARGV[2].rc.F";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].C > $ARGV[2].rc.C";
chdir "..";

open KEGG, ($ARGV[1] =~ /.*\.gz/) ? "gzip -dc $ARGV[1] |" : $ARGV[1] or die $!;
open KT, "> $ourdir/$ARGV[2].ko" or die $!;
my (%ko, %bko);
my $bp;
while(<KEGG>)
{
	chomp;
	if(/^B\s+<b>(.*)<\/b>/)
	{
		$bp = $1;
	}
	if(/^D/)
	{
		my @tmp = split /\t/;
		next if(@tmp < 2);
		if($tmp[0] =~ /^D\s+(\S+)/)
		{
			if(exists $hash{$1})
			{
				my @k = split /\s+/, $tmp[1];
				foreach my $t(@{$hash{$1}})
				{
					$ko{$t}{$k[0]} = 0;
					$bko{$t}{$bp} = 0;
				}
			}
		}
	}
}
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

chdir "$ourdir";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/pathfind.pl -fg $ARGV[2].ko -komap $s -out $ARGV[2].path";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/genDesc.pl -gene2tr $ARGV[2].gen2sym -desc $ARGV[2].desc -pathway $ARGV[2].path -go $ARGV[2] -output $ARGV[2].Annot.tmp";
chdir "..";

open AAA, "$ourdir/$ARGV[2].Annot.tmp" or die $!;
<AAA>;
open FO, ">$ourdir/$ARGV[2].Annot.txt" or die $!;
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

my $out = rel2abs($ourdir);
`/bin/sed 's#^dir=#dir=$out#' /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/gokegg.sh > $out/gokegg.sh`;
`/bin/sed -i 's#^wego=#wego=$out/$ARGV[2]\.wego#' $out/gokegg.sh`;
`/bin/sed -i 's#^ko=#ko=$out/$ARGV[2]\.ko#' $out/gokegg.sh`;
`/bin/sed -i 's#^komap=#komap=$s#' $out/gokegg.sh`;
`/bin/sed -i 's#^go=#go=$out/#' $out/gokegg.sh`;
`/bin/sed -i 's#^go_species=#go_species=$ARGV[2]#' $out/gokegg.sh`;
