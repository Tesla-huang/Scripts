#!/usr/bin/perl -w

# exonCoverage_random.pl can plot the exoncov and random at the same time
# the input file is bam file and please select the align index type (g[Genome]/t[Transcriptome])
# Reviser: Linyifan (Ivan Lam), yflin@genedenovo.com

=head1 Name
		exonCoverage_random.pl

=head1 Introduction
		exonCoverage_random.pl can plot the exoncov and random at the same time
		the input file is bam file and please select the align index type (g[Genome]/t[Transcriptome])
		Reviser: Linyifan (Ivan Lam), yflin@genedenovo.com

=head1 Options
		-ref          The ref.bed file. In refRNAseq pipeline, it was called "all.bed".
		-idx          The type of the align index of the aln.bam file. g[Genome] or t[Transcriptome].
		-in           Input aln.bam file.
		-out          Outprefix of the output files.
		-cov          Whether plot the exoncoverage graph, default is y[yes]. Suffix is .geneBodyCoverage.png
		-random       Whether plot the 5'->3' random graph, default is y[yes]. Suffix is .coverage.png

=head1 Example
		perl exonCoverage_random.pl -ref all.bed -idx t -in A1.bowtie2.bam -out A1
		perl exonCoverage_random.pl -ref all.bed -idx g -in accepted_hits.bam -out A1
		perl exonCoverage_random.pl -ref all.bed -idx t -cov n -random y -in A1.bowtie2.bam -out A1
		

=cut

use utf8;
use strict;
use File::Basename qw{basename};
use Getopt::Long;
use Carp;
use Statistics::Descriptive;

my ($ref, $idx, $cov, $random, $in, $out);
GetOptions(
	"ref=s" => \$ref,
	"idx=s" => \$idx,
	"in=s" => \$in,
	"out=s" => \$out,
	"cov" => \$cov,
	"random" => \$random
);
die ` pod2text $0` unless ($ref&&$out&&$in&&$idx);

$cov="y" unless ($cov);
$random="y" unless ($random);

my %software = map {$_ => (`which $_`)} qw(bedtools samtools Rscript);

foreach my $i (values %software) {
	chomp($i);
}

open my $BED ,'<',$ref      or die "<$ref: $!";
open my $BED5,'>',"$out.5bed" or die ">$out.5bed: $!";

if ($idx =~ /^t/i) {
	while (<$BED>) {
		chomp;
		my ($gene, $range_str) = (split /\t/)[3,10];
		my @ranges = split /,/, $range_str;
		my $startsite = 0;
		my $endsite = 0;
		foreach my $i (@ranges) {
			$endsite += $i;
		}
		print $BED5 join("\t", $gene, $startsite, $endsite, $gene, "+"),"\n";
	}
}elsif ($idx =~ /^g/i) {
	while (<$BED>) {
		chomp;
		my ($chr, $start, $gene, $strand, $range_str, $start_str) = (split /\t/)[0,1,3,5,10,11];
		my @ranges      = split /,/, $range_str;
		my @start_sites = split /,/, $start_str;

		my %end_of;
		for my $i (0 .. $#start_sites) {
			my $Start = $start + $start_sites[$i];
			my $End   = $Start + $ranges[$i];

			if (%end_of) {  #if already has keys...
				EXON:
				for my $start_exon (sort{$a<=>$b} keys %end_of) {
					if ($End < $start_exon or $end_of{$start_exon} < $Start) {
						next EXON;
					}
					if ($Start >= $start_exon) {
						$Start  = $start_exon;
					}
					if ($End <= $end_of{$start_exon}) {
						$End  = $end_of{$start_exon};
					}
					delete $end_of{$start_exon};
				}
			}
			$end_of{$Start} = $End;
		}

		for my $start_exon (sort{$a<=>$b} keys %end_of) {
			print $BED5
			join("\t", $chr, $start_exon, $end_of{$start_exon}, $gene, $strand),"\n";
		}
	}
}else{
	die "the align index type couldn't significant, please select g or t\n";
}

close $BED;
close $BED5;

my $bedver = `$software{bedtools} --version`;
($bedver) = $bedver =~ /v(\d+\.\d+)\./;

if ($bedver < 2.25) {
	run_cmd("$software{bedtools} coverage -d -abam $in -b $out.5bed >$out.5bedstat");
}else{
	run_cmd("$software{bedtools} bamtobed -i $in | bedtools coverage -d -a $out.5bed -b - >$out.5bedstat");
}

unless (-s "$out.5bedstat") {
	run_cmd("$software{samtools} view -uf 0x2 $in | bedtools coverage -d -a $out.5bed -b - >$out.5bedstat");
}

unless (-s "$out.5bedstat") {
	die "The $out.5bedstat couldn't be created, please check the files, options, softwares!\n";
}

my %info;
my %dp;
open my $STAT,'<',"$out.5bedstat" or die "<$out.5bedstat: $!";
while (<$STAT>) {
	chomp;
	my ($gene, $strand, $base, $depth) = (split)[3,4,5,6];
	if ($cov =~ /y/) {
		$info{$gene}{sum} = 0 if (!exists $info{$gene}{sum});
		$info{$gene}{sum} ++ if($base > $info{$gene}{sum});
		$info{$gene}{cov} ++ if($depth > 0);
	}
	if ($random =~ /y/) {
		if ($strand eq "+") {
			push @{$dp{$gene}}, $depth;
		}else{
			unshift @{$dp{$gene}}, $depth;
		}
	}
}
close $STAT;

if ($cov =~ /y/) {
open my $TEST,'>',"$out.test" or die ">$out.test: $!";
my %stat = map {$_ => 0} qw{00-20% 20-40% 40-60% 60-80% 80-100%};

for my $gene (sort keys %info) {
	$info{$gene}{cov} = 0 if (!exists $info{$gene}{cov});
	my $ratio = sprintf("%.2f", $info{$gene}{cov} / $info{$gene}{sum});
	print {$TEST} join("\t", $gene, $info{$gene}{sum},$info{$gene}{cov},$ratio),"\n";

	next if $info{$gene}{cov} == 0;

	my $range = $ratio < 0.2 ? '00-20%'
              : $ratio < 0.4 ? '20-40%'
              : $ratio < 0.6 ? '40-60%'
              : $ratio < 0.8 ? '60-80%'
              :                '80-100%'
              ;
	$stat{$range}++;
}
close $TEST;

open my $COV,'>',"$out.coverage" or die ">$out.coverage: $!";
print {$COV} "percent\tnumber\n";

for my $range (sort keys %stat) {
	print {$COV} $range,"\t",$stat{$range},"\n";
}
close $COV;

my $smpl = basename $out;
open my $R_CMD,'>',"$out.coverage.r" or die ">$out.coverage: $!";
print $R_CMD <<__END_R__;
library(ggplot2)
data = read.table('$out.coverage', header = T, row.names = 1, sep = "\\t")
Percent = sprintf("%s: %d (%2.2f%s)", row.names(data), data[,1], 100*data[,1]/sum(data[,1]), '%')

ggplot(data, aes(x='', y=number, fill=Percent)) +
	geom_bar(stat = "identity", width = 1) +
	coord_polar(theta = 'y') +
	theme(axis.text=element_blank(), axis.ticks=element_blank(), panel.grid=element_blank(), panel.background = element_blank() ) +
	labs(x='',y='',title="Distribution of Genes' Coverage($smpl)")
ggsave('$out.coverage.png', dpi = 200)
__END_R__

run_cmd("$software{Rscript} $out.coverage.r");
}

if ($random =~ /y/) {
	my %pc;
	my @head = ("id");
	for my $i (1..100) {
		push @head, $i;
	}
	push @head, ("all", "21-80", "31-70");
	open WDP, "| gzip > $out.100depth.gz" or die $!;
	print WDP join("\t", @head)."\n";
	foreach my $id (sort keys %dp) {
		my $len = @{$dp{$id}};
		my $s = 0;
		if ($len < 100) {
			my @dp_tmp;
			@dp_tmp = @{$dp{$id}};
			@{$dp{$id}} = ();
			foreach my $depth (@dp_tmp) {
				for my $c (1..10) {
					push @{$dp{$id}}, $depth;
				}
			}
			undef @dp_tmp;
			$len = @{$dp{$id}};
		}
		@{$pc{$id}} = ("$id");
		for my $i (1..100) {
			my $wdp = 0;
			my $end = int($len / 100 * $i) - 1;
			for my $j ($s..$end) {
				$wdp += $dp{$id}[$j];
			}
#			$pc{$id}{$i} = sprintf("%.2f", $wdp / ($end - $s + 1));
			if ($wdp == 0) {
				push @{$pc{$id}}, 0;
			}else{
				push @{$pc{$id}}, sprintf("%.2f", $wdp / ($end - $s + 1));
			}
			$s = $end + 1;
		}
		my $a1_100 = Statistics::Descriptive::Full->new();
		my $a21_80 = Statistics::Descriptive::Full->new();
		my $a31_70 = Statistics::Descriptive::Full->new();
		my @a1_100 = @{$pc{$id}}[1..100];
		my @a21_80 = @{$pc{$id}}[21..80];
		my @a31_70 = @{$pc{$id}}[31..70];
		$a1_100->add_data(\@a1_100);
		$a21_80->add_data(\@a21_80);
		$a31_70->add_data(\@a31_70);
		my $s1_100 = $a1_100->sum();
		my $s21_80 = 0; $s21_80 = sprintf("%.2f", $a21_80->standard_deviation() / $a21_80->mean()) unless ($a21_80->mean() == 0);
		my $s31_70 = 0; $s31_70 = sprintf("%.2f", $a31_70->standard_deviation() / $a31_70->mean()) unless ($a31_70->mean() == 0);
		push @{$pc{$id}}, $s1_100,$s21_80,$s31_70;
		;
		print WDP join("\t",@{$pc{$id}})."\n";
	}
#	close WDP;

	my @total = ("total");
	open ST, "> $out.100depth.stat" or die $!;
	for my $i (1..100) {
		my $wdp = 0;
		foreach my $id (keys %pc) {
			$wdp += $pc{$id}[$i];
		}
		$wdp = sprintf("%.2f", $wdp);
		push @total, $wdp;
		print ST "$i\t$wdp\n";
	}
	close ST;

	my $f1_100 = 0;
#	my @f21_80;
#	my @f31_70;
	foreach my $id (keys %pc) {
		$f1_100 += $pc{$id}[101];
#		push @f21_80, $pc{$id}[102];
#		push @f31_70, $pc{$id}[103];
	}
	push @total, $f1_100,"-","-";
	print WDP join("\t", @total)."\n";
	close WDP;

	open CMD, "> $out.random.r" or die $!;
	print CMD "
	mat <- read.table(\"$out.100depth.stat\", header = F)
	png(\"$out.geneBodyCoverage.png\")
	plot(mat\$V1, mat\$V2, type=\"s\", xlab=\"percentile of gene body(5'->3')\", ylab=\"reads number\", ylim=c(0, max(mat\$V2)))
	dev.off()
	";

	run_cmd("$software{Rscript} $out.random.r");
}

run_cmd("rm -rf $out.5bed $out.5bedstat");
####
sub run_cmd {
    my ($cmd) = @_;

    my $ret = system($cmd);
    $ret == 0
        or croak "Error, CMD: $cmd died with ret($ret)";

    return;
}
