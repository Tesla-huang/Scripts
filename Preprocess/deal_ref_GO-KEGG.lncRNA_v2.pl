#! /usr/bin/perl
use strict;
use warnings;
use File::Spec::Functions qw(rel2abs);

die "perl $0 <go file> <kegg file> <outprefix> <shortname> <GTF> 
go file 5 cols from biomart: Ensembl Gene ID \\t Entrez ID \\t Associated Gene Name \\t GOSlim GOA Accession(s) \\t Description
GTF just for lncRNA mode!~
" unless @ARGV == 5;

my $perl = "/usr/local/bin/perl";
my $shortname = $ARGV[3];

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

my (%g2go, %g2sb, %g2ds, %hash);
open TMP, "$ARGV[2].tmp" or die $!;
while(<TMP>)
{
	chomp;
	my @tmp = split /\t/;
	next if(!exists $gt{$tmp[0]});
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

	push @{$hash{entrez}{$tmp[1]}}, @{$gt{$tmp[0]}} if($tmp[1] ne 0);
	push @{$hash{symbol}{$tmp[2]}}, @{$gt{$tmp[0]}} if($tmp[2] ne 0);
	@{$hash{geneID}{$tmp[0]}} = @{$gt{$tmp[0]}};
}
close TMP;
`rm $ARGV[2].tmp -rf`;

foreach my $i (keys %{$hash{entrez}}){
	@{$hash{entrez}{$i}} = keys { map {$_ => 1} @{$hash{entrez}{$i}}};
}
foreach my $i (keys %{$hash{symbol}}){
	@{$hash{symbol}{$i}} = keys { map {$_ => 1} @{$hash{symbol}{$i}}};
}


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
`$perl /Bio/User/linyifan/script/Preprocess/annot2PFC.pl $ARGV[2].annot $ARGV[2]`;
`$perl /Bio/User/linyifan/script/Preprocess/annot2wego.pl -i $ARGV[2].annot -o $ARGV[2].wego`;
chdir "..";

my $map_title = "/Bio/Database/KEGG/latest_kegg/map_title.tab";
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
				foreach my $id (@{$hash{geneID}{$1}}){
					$ko{$id}{kid} = $kid;
					$ko{$id}{keggid} = "$shortname:$1";
					push(@{$ko{$id}{koid}}, $koid);
					$path{$koid}{cnt}++;
					push(@{$path{$koid}{genes}}, $id);
					push(@{$path{$koid}{kids}}, $kid);
				}
			}
		}
		elsif(/^D\s+(\S+)\s+(\S+);/){
			if(exists $hash{geneID}{$2}){
				foreach my $id (@{$hash{geneID}{$2}}){
					$ko{$id}{kid} = $kid;
					$ko{$id}{keggid} = "$shortname:$1";
					push(@{$ko{$id}{koid}}, $koid);
					$path{$koid}{cnt}++;
					push(@{$path{$koid}{genes}}, $id);
					push(@{$path{$koid}{kids}}, $kid);
				}
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
	my $koid = join ",", @{$ko{$id}{koid}};
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


`$perl /Bio/User/linyifan/script/Preprocess/genDesc_v2.pl -gene2tr $outdir/$ARGV[2].gen2sym -desc $outdir/$ARGV[2].desc -pathway $outdir/$ARGV[2].path.xls -go $outdir/$ARGV[2] -output $outdir/$ARGV[2].Annot.txt`;
