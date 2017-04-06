#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use GO::OntologyProvider::OboParser;

die "perl annot2goa.pl <annot/wego file> <output file prefix>\n" if(@ARGV!=2);

my $annot=shift;
my $outpref=shift;
my $obo_file = "/Bio/Database/GO/go-basic.obo";

my %obsoletes;
my $id;

open GO, "< $obo_file" or die $!;
while (<GO>) {
	chomp;
	if (/^id:\s+(.*)/) {
		$id = $1;
	} elsif (/is_obsolete: true/) {
		$obsoletes{$id} = 1;
	}
}
close GO;

my %genes;

open ANNOT, "$annot" || die $!;
while(<ANNOT>){
	chomp;
	my @t = split /\t/;
#	next if(1 == scalar @t || $t[1] eq "" || $t[1] eq "-" || exists $obsoletes{$t[1]});
#	$genes{$t[0]}{$t[1]} = 1;
	next if (scalar @t == 1);
	my $id = shift @t;
	foreach my $go (@t)
	{
		$genes{$id}{$go} = 1 unless ($go eq "" || $go =~ /-/ || $go !~ /^GO:\d{5}/ || exists $obsoletes{$go});
	}
}
close ANNOT;

foreach my $aspect ("P", "F", "C"){
	my $ol = GO::OntologyProvider::OboParser->new(ontologyFile => $obo_file, aspect => $aspect);
	my %go;
	foreach my $gene (keys %genes){
		foreach my $goid (keys %{$genes{$gene}}){
			my $node = $ol->nodeFromId($goid);
			next unless($node && $node->isValid);
			$go{$node->goid . "\t$gene\t" . $node->term}++;
			foreach my $path($node->pathsToRoot){
				my $n = 0;
				foreach my $i(@{$path}){
					next if(++$n <= 2);
					$go{$i->goid . "\t$gene\t" . $i->term}++;
				}
			}
			delete($genes{$gene}{$goid});
		}
	}

	open PFC, "> $outpref.$aspect" || die $!;
	foreach my $goterm (keys %go){
		print PFC "$goterm\n";
	}
	close PFC;
}

foreach my $gene (keys %genes){
	foreach my $goid (keys %{$genes{$gene}}){
		print STDERR "Unknown GOterm:\t$gene\t$goid\n";
	}
}
