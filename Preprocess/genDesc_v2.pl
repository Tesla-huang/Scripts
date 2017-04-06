#!/usr/bin/perl -w

=pod
description: generate description file
author: Zhang Fangxian, zhangfx@genomics.cn
created date: 20100715
modified date: 20140619, 20110306, 20101122, 20101018, 20101009, 20100907, 20100729
=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin);
#die "$Bin\n";
#use lib "$Bin/lib";
use PerlIO::gzip;

my ($gene2tr, $symbol, $desc, $pathway, $go, $nr, $output, $help);

GetOptions("gene2tr:s" => \$gene2tr, "symbol:s" => \$symbol, "desc:s" => \$desc, "pathway:s" => \$pathway, "go:s" => \$go, "nr:s" => \$nr, "output:s" => \$output, "help|?" => \$help);

if (!defined $gene2tr || (!defined $symbol && !defined $desc && !defined $pathway && !defined $go && !defined $nr) || defined $help) {
	die << "USAGE";
description: generate description file
usage: perl $0 [options]
options:
	-gene2tr <file> *  gene id convert file (***format***: gene<tab>symbol)
	-desc <file>       description of gene (format: gene<tab>description)
	-pathway <file>    using *.path file to add Pathway description
	-go <str>          path and prefix of go files (*.[CFP])
	-nr <file>         add NR description (format: gene<tab>nr<tab>evalue<tab>desc)

	-output <file>     output file, default is STDOUT

	-help|?            help information
e.g.:
	perl $0 -gene2tr huaman.gene2tr -symbol gene_info -go human -output human.desc
USAGE
}

my $g2go = "/Bio/Database/GO/gene2go";

my (@headers) = ("GeneID");
my (%genes);
my $index = 0;

# get gene id
#&showLog("read file $gene2tr");
#&showLog("add symbol");
push @headers, "Symbol";
open IN, "< $gene2tr" or die $!;
while (<IN>) {
	next if (/^\s*$/);
	s/[\r\n]//g;
	my @tabs = split /\t/, $_;
	if(!defined $tabs[1])
	{
		$genes{$tabs[0]}->[$index] = "-";
	}else{
		$genes{$tabs[0]}->[$index] = $tabs[1];
	}
}
close IN;
$index ++;

=cut
# add symbol
if (defined $symbol) {
	&showLog("add symbol");
	push @headers, "Symbol";

	&showLog("read file $symbol");
	if ($symbol =~ /\.gz$/) {
		open DESC, "<:gzip", $symbol or die $!;
	} else {
		open DESC, "< $symbol" or die $!;
	}
	while (<DESC>) {
		next if (/(^#)|(^\s*$)/);
		s/[\r\n]//g;
		my @tabs = split /\t/, $_;
		$genes{$tabs[1]}->[$index] = $tabs[2] if (exists $genes{$tabs[1]});
	}
	close DESC;

	for my $gene (keys %genes) {
		$genes{$gene}->[$index] = "-" if (!defined $genes{$gene}->[$index] || $genes{$gene}->[$index] =~ /^\s*$/);
	}
	$index++;
}
=cut

# add description
if (defined $desc) {
#	&showLog("add description");
	push @headers, "Description";

#	&showLog("read file $desc");
	open DESC, "< $desc" or die $!;
	while (<DESC>) {
		next if (/(^#)|(^\s*$)/);
		s/[\r\n]//g;
		my @tabs = split /\t/, $_;
		$genes{$tabs[0]}->[$index] = $tabs[1] if (exists $genes{$tabs[0]});
	}
	close DESC;

	for my $gene (keys %genes) {
		$genes{$gene}->[$index] = "-" if (!defined $genes{$gene}->[$index] || $genes{$gene}->[$index] =~ /^\s*$/);
	}
	$index++;
}

# add pathway
if (defined $pathway) {
#	&showLog("add pathway");
	my %descs;
	push @headers, "KEGG_A_class", "KEGG_B_class", "Pathway", "K_ID";

#	&showLog("read file $pathway");
	open DESC, "< $pathway" or die $!;
	<DESC>;
	while (<DESC>) {
		next if (/(^#)|(^\s*$)/);
		chomp;
		my @tabs = split /\t/, $_;
		my @genes2 = split /;/, $tabs[5];
		my @k_id = split /\+/, $tabs[6];
#for my $gene (@genes2) {
		for(my $i = 0; $i < @genes2; $i++){
#next if (!exists $genes{$gene});
			next if(!exists $genes{$genes2[$i]});
			if (!exists $descs{$genes2[$i]}){
				@{$descs{$genes2[$i]}{'a'}} = ("$tabs[0]");
				@{$descs{$genes2[$i]}{'b'}} = ("$tabs[1]");
				@{$descs{$genes2[$i]}{'c'}} = ("$tabs[4]//$tabs[2]");
				@{$descs{$genes2[$i]}{'k_id'}} = ($k_id[$i]);
			} else {
				push(@{$descs{$genes2[$i]}{'a'}}, "$tabs[0]");
				push(@{$descs{$genes2[$i]}{'b'}}, "$tabs[1]");
				push(@{$descs{$genes2[$i]}{'c'}}, "$tabs[4]//$tabs[2]");
				push(@{$descs{$genes2[$i]}{'k_id'}}, $k_id[$i]);
			}
		}
	}
	close DESC;

	for my $gene (keys %genes) {
		if(exists $descs{$gene}){
			@{$descs{$gene}{'a'}} = keys { map { $_ => 1 } @{$descs{$gene}{'a'}} };
			@{$descs{$gene}{'b'}} = keys { map { $_ => 1 } @{$descs{$gene}{'b'}} };
			@{$descs{$gene}{'k_id'}} = keys { map { $_ => 1} @{$descs{$gene}{'k_id'}} };
			my $a_class = join ";", @{$descs{$gene}{'a'}};
			my $b_class = join ";", @{$descs{$gene}{'b'}};
			my $c_class = join ";", @{$descs{$gene}{'c'}};
			my $k_id = join ";", @{$descs{$gene}{'k_id'}};
			$genes{$gene}->[$index] = "$a_class\t$b_class\t$c_class\t$k_id";
		}
		else{
			$genes{$gene}->[$index] = "-\t-\t-\t-";
		}
	}
	$index++;
}

# add go
if (defined $go) {
#	&showLog("add go");
	my (%descs, %genes2);

#	&showLog("read file $g2go");
#	if ($g2go =~ /\.gz$/) {
#		open DESC, "<:gzip", $g2go or die $!;
#	} else {
#		open DESC, "< $g2go" or die $!;
#	}
#	while (<DESC>) {
#		next if (/(^#)|(^\s*$)/);
#		s/[\r\n]//g;
#		my @tabs = split /\t/, $_;
#		$descs{$tabs[2]} = $tabs[5];
#	}
#	close DESC;

	my %cfps = ("C" => "Component", "F" => "Function", "P" => "Process");

	for my $cfp (keys %cfps) {
#		&showLog("read file $go.$cfp");
		open GO, "< $go.$cfp" or die $!;
		while (<GO>) {
			s/[\r\n]//g;
			my @tabs = split /\t/, $_;
			$descs{$tabs[0]} = $tabs[2];
			push @{$genes2{$tabs[1]}{$cfp}}, $tabs[0];
		}
		close GO;
	}

	for my $cfp (sort {$a cmp $b} keys %cfps) {
		push @headers, "GO $cfps{$cfp}";
		for my $gene (keys %genes) {
			my $temp = "-";
			if (exists $genes2{$gene}{$cfp}) {
				for my $g (@{$genes2{$gene}{$cfp}}) {
					my $desc = $descs{$g} || "";
					$g .= "//$desc" if ($desc ne "");
				}
				$temp = join ";", @{$genes2{$gene}{$cfp}};
			}
			$genes{$gene}->[$index] = $temp;
		}
		$index++;
	}
}

# add nr
if (defined $nr) {
#	&showLog("add blast nr");
	push @headers, "Blast nr";

	my %descs;
	open DESC, "< $nr" or die $!;
	while (<DESC>) {
		next if (/(^#)|(^\s*$)/);
		s/[\r\n]//g;
		my @tabs = split /\t/, $_;
		my $gene = shift @tabs;
		$descs{$gene} = join "/", @tabs;
	}
	close DESC;

	for my $gene (keys %genes) {
		if (exists $descs{$gene}) {
			$genes{$gene}->[$index] = $descs{$gene};
		} else {
			$genes{$gene}->[$index] = "-";
		}
	}
}

# output
#&showLog("output");
if (defined $output) {
	open OUT, "> $output" or die $!;
	*STDOUT = *OUT;
}
print join("\t", @headers) . "\n";
for my $gene (sort keys %genes) {
	print join("\t", $gene, @{$genes{$gene}}) . "\n";
}
close OUT if (defined $output);

#&showLog("done");

exit 0;

sub showLog {
	my ($info) = @_;
	my @times = localtime; # sec, min, hour, day, month, year
	print STDERR sprintf("[%d-%02d-%02d %02d:%02d:%02d] %s\n", $times[5] + 1900, $times[4] + 1, $times[3], $times[2], $times[1], $times[0], $info);
}
