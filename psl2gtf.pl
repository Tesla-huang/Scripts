#!/usr/bin/env perl

#=head1 Name
#=head1 Introduction
#=head1 Author & Email
#=head1 Options
#=head1 Example
#=cut

use warnings;
use strict;
die "Usage: perl $0 <psl> <out>\n" if @ARGV != 2;

open OUT, "> $ARGV[1]" or die $!;
open OERR, "> $ARGV[0].error" or die $!;
open OGO, "> $ARGV[0].good" or die $!;
my %exists;
open IN, "$ARGV[0]" or die $!;
while (<IN>)
{
	next if ($. < 6);
	chomp;
	my @tmp = split /\s+/, $_;
	my ($gap, $strand, $id, $size, $data_id, $data_s, $data_e, $blocks, $starts) = @tmp[5,8,9,10,13,15,16,18,20];
	chop($blocks);
	my @blocks = split /,/, $blocks;
	my $len = 0;
	foreach my $b (@blocks)
	{
		$len += $b;
	}
	$len += $gap;
	if ($len != $size)
	{
		print OERR "$_\n";
		next;
	}
	else
	{
		if (!exists $exists{$id})
		{
			$exists{$id} = 1;
		}
		else
		{
			$id .= ".$exists{$id}";
			$exists{$id} ++;
		}
		print OGO "$_\n";
		chop($starts);
		my $frame = 0;
		my @starts = split /,/, $starts;
		foreach my $i (0 .. $#blocks)
		{
			my $start = $starts[$i] + 1;
			my $end = $starts[$i] + $blocks[$i];
			print OUT "$data_id\tBlat\texon\t$start\t$end\t.\t$strand\t.\tgene_id \"$id\"; transcript_id \"$id\";\n";
			print OUT "$data_id\tBlat\tCDS\t$start\t$end\t.\t$strand\t$frame\tgene_id \"$id\"; transcript_id \"$id\";\n";
			$frame = 3 - ($end - $start + 1 - $frame) %3;
			$frame = 0 if ($frame == 3);
		}
	}
}
