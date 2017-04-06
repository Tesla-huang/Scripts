#!/usr/bin/env perl

=head1 Name
		fdr.calculator.pl

=head1 Introduction
		calculate the fdr of input qvalue

=head1 Author & Email
		Ivan Lam & yflin@genedenovo.com

=head1 Options
		-in			input table which contain the P value
		-out			output filename
		-head			the flag of header
		-pv			the P value colume number. the FDR will add insert the right of -pv

=head1 Example
		perl fdr.calculator.pl -in diff.xls -out new.diff.xls -head -pv 10

=cut

use warnings;
use strict;
use Getopt::Long;

my ($in, $out, $head, $pc);
GetOptions(
		"in=s"    => \$in,
		"out=s"   => \$out,
		"head"    => \$head,
		"pv=i"    => \$pc
		);

die `pod2text $0` unless ($pc && $in && $out);

open IN, "$in" or die $!;

my $header;
if ($head)
{
	$header = <IN>;
	chomp($header);
	my @header = split /\t/, $header;
	splice(@header, $pc, 0, "FDR");
	$header = join("\t", @header)."\n";
}

my %pv;
while (<IN>)
{
	chomp;
	my @tmp = split /\t/, $_;
	$tmp[$pc-1] = 1 if $tmp[$pc-1] =~ /NA/i or $tmp[$pc-1] < 0 or $tmp[$pc-1] > 1;
	$pv{$tmp[0]} = $tmp[$pc-1];
}
close IN;

my %qv;
my @pv = sort {$a <=> $b} values %pv;
my $last = -1;
my $lastpv = 0;
my $lastqv = 0;
foreach my $i (0 .. $#pv)
{
	if ($last == -1)
	{
		$last = $i + 1;
		$lastpv = $pv[$i];
		$lastqv = (@pv / $last) * $lastpv;
		$lastqv = 1 if $lastqv > 1;
		$qv{$lastpv} = $lastqv;
	}
	elsif ($pv[$i] == $lastpv)
	{
		next;
	}
	else
	{
		$last = $i + 1;
		$lastpv = $pv[$i];
		my $qv_tmp = (@pv / $last) * $lastpv;
		$qv_tmp = 1 if $qv_tmp > 1;
		$qv_tmp = $lastqv if ($qv_tmp < $lastqv);
		$qv{$lastpv} = $qv_tmp;
		$lastqv = $qv_tmp;
	}
}

open IN, "$in" or die $!;
if ($head)
{
	<IN>;
}
open OUT, "> $out" or die $!;
print OUT "$header";
while (<IN>)
{
	chomp;
	my @tmp = split /\t/, $_;
	my $qv;
	if (exists $qv{$tmp[$pc-1]})
	{
		$qv = $qv{$tmp[$pc-1]};
	}
	else
	{
		$qv = "NA";
	}
	splice(@tmp, $pc, 0, $qv);
	print OUT join("\t",@tmp)."\n";
}
