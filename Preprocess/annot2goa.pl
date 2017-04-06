#! /usr/bin/perl
# author: Liu Hang, liuhang@genomics.cn
# create date: 20090807
# 20101203, 20091110, 20091030, 20090907, 20090905, 20090818, Zhang Fangxian, zhangfx@genomics.cn

use strict;
use File::Basename 'dirname';
use FindBin qw($Bin);
use lib "$Bin";
#use Support_Program;

#my $go = [grep {-e $_} ("/ifs1/DGE_SR/zhangfx/db/go/gene_ontology.1_2.obo", "/ifshk1/DGE_SR/zhangfx/db/go/gene_ontology.1_2.obo")]->[0];
my %confi=();
my $path1 = $Bin;
#Support_Program(\%confi,$path1);
my $go = "/Bio/Database/Database/GO_April2015/gene_ontology.1_2.obo";

die "perl annot2goa.pl <annot file> <output file prefix>\n" if(@ARGV!=2);
my $annot=shift;
my $outpref=shift;

my (%gos, %obsoletes);
my ($id, $name, $namespace);
open GO, "< $go" or die $!;
while (<GO>) {
	chomp;
	if (/^id:\s+(.*)/) {
		$id = $1;
	} elsif (/^name:\s+(.*)/) {
		$name = $1;
	} elsif (/^namespace:\s+(.*)/) { # molecular_function, biological_process, cellular_component
		$namespace = $1;
		$gos{$namespace}{$id} = 1;
	} elsif (/is_obsolete: true/) {
		$obsoletes{$id} = 1;
	}
}
close GO;

for $namespace (keys %gos) {
	for $id (keys %{$gos{$namespace}}) {
		delete $gos{$namespace}{$id} if (exists $obsoletes{$id});
	}
}

my $GOP="";
my $GOF="";
my $GOC="";

open (A, "$annot") or die "fail to open $annot: $!\n";
while(<A>){
	s/[\r\n]//g;
	my @tmp=split(/\t/,$_);
	my ($id)=split(/\s/,$tmp[0]);
	$GOF.="_	$id	$id	_	$tmp[1]	GOA	ISA	_	F	_	_	_	_	_	_\n" if (exists $gos{"molecular_function"}{$tmp[1]});
	$GOP.="_	$id	$id	_	$tmp[1]	GOA	ISA	_	P	_	_	_	_	_	_\n" if (exists $gos{"biological_process"}{$tmp[1]});
	$GOC.="_	$id	$id	_	$tmp[1]	GOA	ISA	_	C	_	_	_	_	_	_\n" if (exists $gos{"cellular_component"}{$tmp[1]});
}
close A;


open (B,">$outpref.F") or die "fail to write $outpref.F: $!\n";
print B $GOF;
close B;
open (B,">$outpref.P") or die "fail to write $outpref.P: $!\n";
print B $GOP;
close B;
open (B,">$outpref.C") or die "fail to write $outpref.C: $!\n";
print B $GOC;
close B;

my $outdir = dirname("$outpref.C");
my $name = $outpref;
$name =~ s/^.*\///;

for my $pfc (("P", "F", "C")) {
	my $conf = <<CONF;
###################################
annotationFile = $name.$pfc
ontologyFile = $go
aspect = $pfc
geneUrl = http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=<REPLACE_THIS>

pvalueCutOff = 1
calculateFDR = 1
#################################

goidUrl = http://amigo.geneontology.org/amigo/medial_search?q=<REPLACE_THIS>


maxNode = 30

minMapWidth = 350

minMapHeight4TopKey = 600

minMapWidth4OneLineKey = 620

widthDisplayRatio = 0.8

heightDisplayRatio = 0.8

binDir = /tools/graphviz/current/bin/

libDir = /tools/graphviz/current/lib/

mapNote =

totalNumGene =

outDir =
CONF

	open CONF, "> $outdir/$pfc.conf" or die $!;
	print CONF $conf;
	close CONF;
}

exit 0;
