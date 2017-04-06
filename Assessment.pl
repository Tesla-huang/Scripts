#!/usr/bin/perl -w

=head1 Name
                Assessment.pl

=head1 Introduction
                Assessment.pl can plot the saturation, exonCoverage and 5'->3' random at the same time.
                the input file is bam file and only generated in RSEM

=head1 Options
                -ref          The ref.fa file. In refRNAseq pipeline, it was called "all.exon.fa" in RSEM.
                -type         The read type. '1' for SE, '2' for PE. Also, You can use "se" or "pe" to instead the "1" or "2".
                -in           Input aln.bam file.
                -out          Outprefix of the output files.
                -plot         scr. 's' is Saturation[.saturation.png], 'c' is exonCoverage[.coverage.png], 'r' is 5'->3' Random[.geneBodyCoverage.png].
                              default is plot these three graph 'scr'. if you don't want to plot any one of them, don't input its symbol[scr].

=head1 Example
                perl Assessment.pl -ref all.fa -type 2 -in A1.bowtie2.bam -out A1
                perl Assessment.pl -ref all.fa -type 2 -in A1.bowtie2.bam -out A1 -plot sc
                
=cut

use strict;
use Getopt::Long;
use File::Basename qw{basename};
use Carp;

my ($ref, $type, $in, $out, $plot);
GetOptions(
		"ref=s"   => \$ref,
		"type=s"  => \$type,
		"in=s"    => \$in,
		"out=s"   => \$out,
		"plot=s"  => \$plot
);
die `pod2text $0` unless ($ref && $type && $in && $out);
$plot = "scr" unless ($plot);
$type = 1 if ($type =~ /se/i);
$type = 2 if ($type =~ /pe/i);

my $name = basename $out;
my $flag = 0;
my $error = "The Assessment.pl die because:";
my %software = map {$_ => (`which $_`)} qw(samtools Rscript);
foreach my $i (keys %software) {
	if ($software{$i} eq "") {
		$error .= "\nThe $i is not exists in the system.";
		$flag ++;
	}
}

unless ($type eq "1" || $type eq "2") {
	$error .= "\n\"$type\" is unknown -type, please use \"1\" for SE, \"2\" for PE.";
	$flag ++;
}

unless (-s "$ref") {
	$error .= "\n$ref is not exists.";
	$flag ++;
}

unless (-s "$in") {
	$error .= "\n$in is not exists.";
	$flag ++;
}

unless ($plot =~ /[SsCcRr]/) {
	$error .= "\n$plot may be wrong.";
	$flag ++;
}

unless ($flag == "0") {
	die "$error\nPlease check these Error information\n";
}

### deal ref
my %len;
open FA, "$ref" or die "can't open:$!";
local $/ = "\n>";
while (<FA>) {
	s/^>//;
	chomp;
	my @tmp = split /\n/, $_, 2;
	my $id = (split /\s+/, $tmp[0])[0];
	$tmp[1] =~ s/\s+//g;
	$len{$id} = length($tmp[1]);
}
local $/ = "\n";


#my $type=2;   ### for pe reads
#my $type=1;   ### for se reads

### for saturation
my $sum = keys %len;
my $saturation_window = 100000;
my %saturation;
my $mark = 0;
my $last_reads = "";
my $reads_cnt = 0;
my %genes_cnt;

### for coverage
my %gene_coverage_beg;
my %gene_coverage_end;

### for random
my %depth_window;
my $window=100;
my %hash_window;
foreach my $id (keys %len) {
	my $window_len=sprintf("%.2f",$len{$id}/$window);
	my $start=0;
	for(my $i=1; $i<=$window;$i++)
	{
		my $end=$start+$window_len;
		$hash_window{$id}{$i}="$start\t$end";
		$start=$start+$window_len;
	}
}

open BAM,"samtools view $in |" or die "cannot open:$!";
while(<BAM>)
{
	if($.%1000000==0)
	{
		my $date=`date`;
		print STDERR "[$name] RUNNING INFO: processed $. lines. $date";
#		last if($.==3000000);
	}
	next if($. % $type==1);

	chomp;    my @a=split(/\t/,$_);
	my $align_start=0;     my $align_end=0;
	if($a[8]<0)
	{
		$align_end=$a[3]+(length $a[9])-1;
		$align_start=$align_end-abs($a[8])+1;
	}
	elsif($a[8]>0)
	{
		$align_start=$a[3];
		$align_end=$align_start+$a[8]-1;
	}
	else    ### for se
	{
		$align_start=$a[3];
		$align_end=$align_start+(length $a[9])-1;
	}

##### random
	if(exists $hash_window{$a[2]})
	{
		my $win_beg=int($align_start*$window/$len{$a[2]});
		$win_beg=$win_beg>=1?$win_beg:1;
		foreach my $o($win_beg .. $window)
		{
			my @win=split(/\t/,$hash_window{$a[2]}{$o});
			if($win[0]>$align_end)
			{
				last;
			}
			elsif($win[1]<$align_start)
			{
				next;
			}
			else
			{
				my $overlap=&overlap($win[0],$win[1],$align_start,$align_end);
				$depth_window{$a[2]}{$o}+=$overlap/($win[1]-$win[0]);
			}
		}
	}
	else
	{
		print STDERR "Wrong code 11112222\n";
		die;
	}

##### coverage
	if(exists $gene_coverage_beg{$a[2]})
	{
		my @beg=@{$gene_coverage_beg{$a[2]}};
		my @end=@{$gene_coverage_end{$a[2]}};
		my @tmp_beg=();    my @tmp_end=();
		foreach my $o (0 .. $#beg)
		{
			if($beg[$o]>$align_end+1)
			{
				push @tmp_beg,$align_start;
				push @tmp_end,$align_end;
				foreach my $i ($o .. $#beg)
				{
					push @tmp_beg,$beg[$i];
					push @tmp_end,$end[$i];
				}
				last;
			}
			elsif($end[$o]<$align_start-1)
			{
				push @tmp_beg,$beg[$o];
				push @tmp_end,$end[$o];
				if($o == $#beg)
				{
					push @tmp_beg,$align_start;
					push @tmp_end,$align_end;
				}
				next;
			}
			else
			{
				my $ret=&union($beg[$o],$end[$o],$align_start,$align_end);
				if($ret ne "no")
				{
					my @tmp=split(/\t/,$ret);
					$align_start=$tmp[0];
					$align_end=$tmp[1];
					if($o == $#beg)
					{
						push @tmp_beg,$align_start;
						push @tmp_end,$align_end;
					}
				}
				else
				{
					print STDERR "wrong code:1234567\n";
					die;
				}
			}
		}
		@{$gene_coverage_beg{$a[2]}}=();
		push @{$gene_coverage_beg{$a[2]}},@tmp_beg;
		@{$gene_coverage_end{$a[2]}}=();
		push @{$gene_coverage_end{$a[2]}},@tmp_end;
	}
	else
	{
		push @{$gene_coverage_beg{$a[2]}},$align_start;
		push @{$gene_coverage_end{$a[2]}},$align_end;
	}

##### saturation
	if ($mark == 0)
	{
		$last_reads = $a[0]; $mark = 1; $genes_cnt{$a[2]}++; $reads_cnt++;
	}
	else
	{
		if ($last_reads eq $a[0])
		{
			$genes_cnt{$a[2]}++;
		}
		else
		{
			$genes_cnt{$a[2]}++;
			$reads_cnt++;
			$last_reads = $a[0];
			if ($reads_cnt % ($saturation_window/$type) == 0)
			{
				my $tmp = int($reads_cnt/($saturation_window/$type));
				$saturation{$tmp} = keys %genes_cnt;
			}
		}
	}
}
close BAM;

open OUT, "| gzip > $out.depthcovarage.gz" or die $!;
print OUT "id\t",join("\t",1 .. $window),"\tall depth\tcover length\tgene length\tcover ratio\n";
my %coverage = map {$_ => 0} qw{00-20% 20-40% 40-60% 60-80% 80-100%};
my %total;
my $total_cover=0;
my $total_length=0;
foreach my $id (sort keys %hash_window)
{
	print OUT "$id";
	my $all=0;
	foreach my $i (1 .. $window)
	{
		if(exists $depth_window{$id}{$i})
		{
			my $tmp=sprintf("%.2f",$depth_window{$id}{$i});
			print OUT "\t$tmp";
			$total{$i}+=$tmp;
			$all+=$tmp;
		}
		else
		{
			print OUT "\t0";
		}
	}
	my $cover=0;
	if(exists $gene_coverage_beg{$id})
	{
		my @beg=@{$gene_coverage_beg{$id}};
		my @end=@{$gene_coverage_end{$id}};
		foreach my $i (0 .. $#beg)
		{
			$cover+=$end[$i]-$beg[$i]+1;
		}
	}
	$total_cover+=$cover;
	$total_length+=$len{$id};
	my $cover_ratio=sprintf("%.2f",$cover/$len{$id}*100);
	if ($cover_ratio > 0) {
		my $range = $cover_ratio < 20 ? '00-20%'
			: $cover_ratio < 40 ? '20-40%'
			: $cover_ratio < 60 ? '40-60%'
			: $cover_ratio < 80 ? '60-80%'
			:                     '80-100%'
			;
		$coverage{$range} ++;
	}
	print OUT "\t$all\t$cover\t$len{$id}\t$cover_ratio\n";
}
print OUT "total";
my $all=0;
foreach my $w (1 .. $window)
{
	if(exists $total{$w})
	{
		print OUT "\t",sprintf("%.2f",$total{$w});
		$all+=sprintf("%.2f",$total{$w});
	}
	else
	{
		print OUT "\t0";
	}
}
my $total_cover_ratio=sprintf("%.2f",$total_cover/$total_length*100);
print OUT "\t$all\t$total_cover\t$total_length\t$total_cover_ratio\n";
close OUT;

if ($plot =~ /s/i) {
	open SAT, "> $out.saturation.stat" or die "cannot open: $!";
	print SAT "0\t0.0000\t$sum\n";
	foreach my $o (sort {$a <=> $b} keys %saturation)
	{
		my $ratio = sprintf("%.4f",$saturation{$o}/$sum*100);
		print SAT "$o\t$ratio\t$saturation{$o}\n";
	}
	close SAT;
	open RCMD, "> $out.saturation.r" or die $!;
	print RCMD "
		mat = read.table(\"$out.saturation.stat\", header = F, sep = \"\t\")
		png(file=\"$out.saturation.png\")
		plot(mat\$V1, mat\$V2, type = \"l\", ylim=c(0,105), xlab=\"mapped reads(X $saturation_window)\", ylab=\"gene number(%)\", cex=1.5, cex.axis=1.5, cex.lab=1)
		grid(col = \"gray\")
		dev.off()
		";
	close RCMD;
	run_cmd("Rscript $out.saturation.r");
}

if ($plot =~ /c/i) {
	open COV, "> $out.coverage" or die $!;
	print COV "percent\tnumber\n";
	for my $range (sort keys %coverage) {
		print COV $range,"\t",$coverage{$range},"\n";
	}
	close COV;
	open RCMD, "> $out.coverage.r" or die $!;
	print RCMD "
		library(ggplot2)
		data = read.table('$out.coverage', header = T, row.names = 1, sep = \"\\t\")
		Percent = sprintf(\"%s: %d (%2.2f%s)\", row.names(data), data[,1], 100*data[,1]/sum(data[,1]), '%')
		
		ggplot (data, aes(x='', y=number, fill=Percent)) +
			geom_bar(stat = \"identity\", width = 1) +
			coord_polar(theta = 'y') +
			theme(axis.text=element_blank(), axis.ticks=element_blank(), panel.grid=element_blank(), panel.background = element_blank()) +
			labs(x='',y='',title=\"Distribution of Genes' Coverage($name)\")
		ggsave('$out.coverage.png',dpi = 200)
		";
	close RCMD;
	run_cmd("Rscript $out.coverage.r");
}

if ($plot =~ /r/i) {
	my $tmp = `zcat $out.depthcovarage.gz | tail -n 1`;
	print STDERR "The $out.depthcovarage.gz is wrong!\n" unless ($tmp =~ /^total/i);
	open RAN, "> $out.100depth.stat" or die $!;
	chomp($tmp);
	my @tmp = split /\t/, $tmp;
	for my $i (1..100) {
		print RAN "$i\t$tmp[$i]\n";
	}
	close RAN;
	open RCMD, "> $out.random.r" or die $!;
	print RCMD "
		mat <- read.table(\"$out.100depth.stat\", header = F)
		png(\"$out.geneBodyCoverage.png\")
		plot(mat\$V1, mat\$V2, type=\"s\", xlab=\"percentile of gene body(5'->3')\", ylab=\"reads number\", ylim=c(0, max(mat\$V2)))
		dev.off()
		";
	close RCMD;
	run_cmd("Rscript $out.random.r");
}

####
sub overlap
{
	my ($window_start,$window_end,$align_start,$align_end)=@_;
	my $start=$window_start>=$align_start?$window_start:$align_start;
	my $end=$window_end<=$align_end?$window_end:$align_end;
	my $overlap=0;
	if($start==$align_start)
	{
		$overlap=$end-$start+1;
	}
	if($start==$window_start)
	{
		$overlap=$end-$start;
	}
	return $overlap;
}

sub union
{
	my ($window_start,$window_end,$align_start,$align_end)=@_;
	my $o_start=$window_start>=$align_start?$window_start:$align_start;
	my $o_end=$window_end<=$align_end?$window_end:$align_end;
	my $start=$window_start<$align_start?$window_start:$align_start;
	my $end=$window_end>$align_end?$window_end:$align_end;
	if($o_start<=$o_end+1)
	{
		my $tmp="$start\t$end";
		return $tmp;
	}
	else
	{
		return "no";
	}
}

sub run_cmd {
	my ($cmd) = @_;

	my $ret = system($cmd);
	$ret == 0
		or croak "Error, CMD: $cmd died with ret($ret)";

	return;
}
