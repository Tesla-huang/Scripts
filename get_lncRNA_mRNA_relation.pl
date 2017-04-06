#!usr/bin/perl -w
use strict;
my $distan=shift;
my $file=shift;
open(IN,$file)||die"cannot open:$!";
my %hash;
while(<IN>)
{
	chomp;   my @a=split(/\t/,$_);
	$hash{$a[1]}{$a[2]}=$_;
}
close IN;

my $lincRNA_file=shift;
print "lncRNA_ID\tchr\tstart\tend\tstrand\tGeneID\tchr\tstart\tend\tstrand\tup/down_Stream\tdistance\n";
open(IN,$lincRNA_file)||die"cannot open:$!";
while(<IN>)
{
	chomp;   my @a=split(/\t/,$_);
	foreach my $out (sort {$a<=>$b} keys %{$hash{$a[1]}})
	{
		my @b=split(/\t/,$hash{$a[1]}{$out});
		if($a[3]<$b[2]-$distan)
		{
			last;
		}
		if($a[2]>$b[3]+$distan)
		{
			next;
		}
		if($a[2]>=$b[2]-$distan && $a[3]<=$b[3]+$distan)
		{
			my $dis=0;    my $mark;
			if($b[2]>$a[3])
			{
				$dis=$b[2]-$a[3]-1;
				if($a[4] eq "+")
				{
					$mark="UPSTREAM";
				}
				else
				{
					$mark="DOWNSTREAM";
				}
			}
			if($b[3]<$a[2])
			{
				$dis=$a[2]-$b[3]-1;
				if($a[4] eq "+")
				{
					$mark="DOWNSTREAM";
				}
				else
				{
					$mark="UPSTREAM";
				}
			}
			if($dis==0)
			{
				$mark="OVERLAP";   $dis=-1;
			}
			my @dd=split(/\t/,$hash{$a[1]}{$out});
			if($a[0] ne $dd[0])
			{
				print "$_\t$hash{$a[1]}{$out}\t$mark\t$dis\n";
			}
		}
	}
}
close IN;
