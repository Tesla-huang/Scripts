#!/usr/bin/env perl
use warnings;
use strict;
use File::Spec::Functions qw(rel2abs);

die "perl $0 <go file> <kegg file> <outprefix> <shortname>
go file 5 cols from biomart: Ensembl Gene ID \\t Entrez ID \\t Associated Gene Name \\t GOSlim GOA Accession(s) \\t Description
" unless @ARGV == 4;

my (%hash, %ts);
my $shortname = $ARGV[3];
open GO, (($ARGV[0] =~ /.*\.gz/) ? "gzip -dc $ARGV[0] |" : $ARGV[0]) or die $!;
<GO>;
my $outdir = "$ARGV[2]\_annot";
system "mkdir $outdir";
open GT, "> $outdir/$ARGV[2].annot" or die $!;
open GS, "> $outdir/$ARGV[2].gen2sym" or die $!;
my %g2s;

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
	push @{$hash{entrez}{$tmp[1]}}, $tmp[0] if(defined $tmp[1]);
	push @{$hash{symbol}{$tmp[2]}}, $tmp[0] if(defined $tmp[2]);
	@{$hash{geneID}{$tmp[0]}} = ();
}
close GO;
close GT;

foreach my $i (keys %{$hash{entrez}}){
	@{$hash{entrez}{$i}} = keys { map {$_ => 1} @{$hash{entrez}{$i}}};
}
foreach my $i (keys %{$hash{symbol}}){
	@{$hash{symbol}{$i}} = keys { map {$_ => 1} @{$hash{symbol}{$i}}};
}

foreach(keys %g2s)
{
	foreach my $i(keys %{$g2s{$_}})
	{
		print GS "$_\t$i\n";
	}
}

open DESC, "> $outdir/$ARGV[2].desc" or die $!;
foreach my $t(keys %ts)
{
	print DESC "$t\n";
}

chdir "$outdir";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/annot2PFC.pl $ARGV[2].annot $ARGV[2]";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/annot2wego.pl -i $ARGV[2].annot -o $ARGV[2].wego";
#system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].P > $ARGV[2].rc.P";
#system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].F > $ARGV[2].rc.F";
#system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/reconstructGO.pl $ARGV[2].C > $ARGV[2].rc.C";
chdir "..";

my $map_title = "/Bio/Database/Database/kegg/latest_kegg/map_title.tab";
my %map_title;
open TITLE, "$map_title" or die $!;
while (<TITLE>)
{
	next if (/^#/ or /^\s*$/);
	chomp;
	my @tmp = split /\t/, $_;
	my $ko = shift @tmp;
	$map_title{$ko} = \@tmp;
}
close TITLE;

open KEGG, ($ARGV[1] =~ /.*\.gz/) ? "gzip -dc $ARGV[1] |" : $ARGV[1] or die $!;
my ($a_class, $b_class, $pathway, $koid) = ("-", "-", "-", "-");
my (%path, %ko);
while(<KEGG>)
{
	chomp;
	if(/^A<b>(.*)<\/b>/){
		$a_class = $1;
	}
	elsif(/^B\s+<b>(.*)<\/b>/)
	{
		$b_class = $1;
	}
	elsif(/^C/){
		next if($a_class eq "Human Diseases" && $shortname ne "hsa");
		if(/PATH:$shortname(\d{5})/){
			$koid = $1;
			next if (!exists $map_title{$koid});
			my @tmp = split /\s+/;
			shift @tmp; shift @tmp; pop @tmp;
			$pathway = join " ", @tmp;
			$path{$koid}{a_class} = $a_class;
			$path{$koid}{b_class} = $b_class;
			$path{$koid}{name} = $pathway;
			$path{$koid}{cnt} = 0;
			@{$path{$koid}{genes}} = ();
			@{$path{$koid}{kids}} = ();
		}
		else{
			$koid    = "-";
			$pathway = "-";
		}
	}
	elsif(/^D/)
	{
		next if($a_class eq "Human Diseases" && $shortname ne "hsa");
		next if($koid eq "-" || $pathway eq "-");
		next if (!exists $map_title{$koid});
		my $kid;
		if(/(K\d{5})/){
			$kid = $1;
		}
		else{
			next;
		}
		if(/^D\s+(\S+)/){
			if(exists $hash{entrez}{$1}){
				foreach my $id (@{$hash{entrez}{$1}}){
					$ko{$id}{kid} = $kid;
					$ko{$id}{keggid} = "$shortname:$1";
					push(@{$ko{$id}{koid}}, $koid);
					$path{$koid}{cnt}++;
					push(@{$path{$koid}{genes}}, $id);
					push(@{$path{$koid}{kids}}, $kid);
				}
			}
			elsif(exists $hash{geneID}{$1}){
				my $id = $1;
				$ko{$id}{kid} = $kid;
				$ko{$id}{keggid} = "$shortname:$1";
				push(@{$ko{$id}{koid}}, $koid);
				$path{$koid}{cnt}++;
				push(@{$path{$koid}{genes}}, $id);
				push(@{$path{$koid}{kids}}, $kid);
			}
		}
		elsif(/^D\s+(\S+)\s+(\S+);/){
			if(exists $hash{geneID}{$2}){
				my $id = $2;
				$ko{$id}{kid} = $kid;
				$ko{$id}{keggid} = "$shortname:$1";
				push(@{$ko{$id}{koid}}, $koid);
				$path{$koid}{cnt}++;
				push(@{$path{$koid}{genes}}, $id);
				push(@{$path{$koid}{kids}}, $kid);
			}
			elsif(exists $hash{symbol}{$2}){
				foreach my $id (@{$hash{symbol}{$2}}){
					$ko{$id}{kid} = $kid;
					$ko{$id}{keggid} = "$shortname:$1";
					push(@{$ko{$id}{koid}}, $koid);
					$path{$koid}{cnt}++;
					push(@{$path{$koid}{genes}}, $id);
					push(@{$path{$koid}{kids}}, $kid);
				}
			}
		}
	}
}

my $unigene_cnt = keys %ko;

open KT, "> $outdir/$ARGV[2].kopath" or die $!;
foreach my $id (keys %ko){
	my %count;
	my @koid = grep { ++$count{ $_ } < 2; } @{$ko{$id}{koid}};
	my $koid = join ",", @koid;
	print KT "$id\t$ko{$id}{kid}\t$koid\t$ko{$id}{keggid}\n";
}
close KT;


open PATH, "> $outdir/$ARGV[2].path.xls" or die $!;
print PATH "KEGG_A_class\tKEGG_B_class\tPathway\tCount ($unigene_cnt)\tPathway ID\tGenes\tKOs\n";
foreach my $koid (sort {$path{$b}{cnt} <=> $path{$a}{cnt}} keys %path){
	my $genes = join ";", @{$path{$koid}{genes}};
	my $kids = join "+", @{$path{$koid}{kids}};
	print PATH "$path{$koid}{a_class}\t$path{$koid}{b_class}\t$path{$koid}{name}\t$path{$koid}{cnt}\tko$koid\t$genes\t$kids\n";
}
close PATH;

chdir "$outdir";
system "perl /Bio/Bin/pipe/RNA/ref_RNASeq/Preprocess/genDesc_v2.pl -gene2tr $ARGV[2].gen2sym -desc $ARGV[2].desc -pathway $ARGV[2].path.xls -go $ARGV[2] -output $ARGV[2].Annot.txt";
chdir "..";
