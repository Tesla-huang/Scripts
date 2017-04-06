#!/usr/bin/perl -w
use strict;

die "Usage: perl $0 <bed> <bam> <outprefix>\n" if @ARGV !=3 ;
my ($bed_file, $bam_file, $out) = @ARGV;

open(IN,$bed_file)||die"cannot open:$!";
my $window=100;
my %hash_window;
my %fa_len;
while(<IN>)
{
	chomp;     my @a=split(/\t/,$_);
	$fa_len{$a[0]}=$a[2]-$a[1]+1;
	my $window_len=sprintf("%.2f",$fa_len{$a[0]}/$window);
	my $start=0;
	for(my $i=1; $i<=$window;$i++)
	{
		my $end=$start+$window_len;
		$hash_window{$a[0]}{$i}="$start\t$end";
		$start=$start+$window_len;
	}
}
close IN;


my %depth_window;
open(IN,"samtools view $bam_file|")||die"cannot open:$!";
while(<IN>)
{
	chomp;    my @a=split(/\t/,$_);
	if($.%1000000==0)
	{
		my $date=`date`;
		print STDERR "RUNNING INFO: $date processed $. lines.\n";
	}
	if(exists $hash_window{$a[2]})
	{
		my $align_start=$a[3];
		my $align_end=$a[3]-1+length $a[9];
		my $win_beg=int($align_start*$window/$fa_len{$a[2]});
		$win_beg=$win_beg>=1?$win_beg:1;
		foreach my $out($win_beg .. $window)
		{
			my @win=split(/\t/,$hash_window{$a[2]}{$out});
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
				$depth_window{$a[2]}{$out}+=$overlap/($win[1]-$win[0]);
			}
		}
	}
}
close IN;

open OUT, "> $out.depth" or die $!;
print OUT "gene\t",join("\t",1 .. $window),"\n";
my %total;
foreach my $out(sort keys %hash_window)
{
	print OUT "$out";
	foreach my $in(1 .. $window)
	{
		if(exists $depth_window{$out}{$in})
		{
			my $tmp=sprintf("%.2f",$depth_window{$out}{$in});
			print OUT "\t$tmp";
			$total{$in}+=$tmp;
		}
		else
		{
			print OUT "\t0";
		}
	}
	print OUT "\n";
}
print OUT "total";
foreach my $out(1 .. $window)
{
	if(exists $total{$out})
	{
		print OUT "\t",sprintf("%.2f",$total{$out});
	}
	else
	{
		print OUT "\t0";
	}
}
print OUT "\n";
close OUT;

my $plot = "/home/linyifan/script/random.r";
`tail -1 $out.depth | tr '\t' '\n' | sed 1d | awk '{OFS="\t";print NR,\$0}' > $out.window`;
`Rscript $plot $out.window`;

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
