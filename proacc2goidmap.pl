#!/usr/bin/env perl

use warnings;
use strict;

die "Usage: perl $0 <*.attri> <t/g> <idmap> <out>\n" if @ARGV != 4;

open IN, "$ARGV[0]" or die $!;
my %hash;
my %acc;
my %acc2go;

if ($ARGV[1] =~ /t/i)
{
	while (<IN>)
	{
		next if (/^#/);
		chomp;
		my @tmp = split /\t/, $_;
		if ($tmp[4] !~ /^\s*-*$/)
		{
			push @{$hash{$tmp[0]}}, $tmp[4];
			$acc{$tmp[4]} = 1;
		}
		if ($tmp[3] !~ /^\s*-*$/)
		{
			push @{$hash{$tmp[0]}}, $tmp[3];
			$acc{$tmp[3]} = 1;
		}
	}
}
elsif ($ARGV[1] =~ /g/i)
{
	while (<IN>)
	{
		next if (/^#/);
		chomp;
		my @tmp = split /\t/, $_;
		if ($tmp[4] !~ /^\s*-*$/)
		{
			push @{$hash{$tmp[1]}}, $tmp[4];
			$acc{$tmp[4]} = 1;
		}
		if ($tmp[3] !~ /^\s*-*$/)
		{
			push @{$hash{$tmp[1]}}, $tmp[3];
			$acc{$tmp[3]} = 1;
		}
	}
}
close IN;

open IN, "$ARGV[2]" or die $!;
while (<IN>)
{
	chomp;
	my @tmp = split /\t/, $_;
	shift @tmp;
	my $id1 = shift @tmp;
	my $id2 = shift @tmp;
	if ($id1)
	{
		$id1 =~ s/\s//g;
		my @id1 = split /;/, $id1;
		foreach my $i (@id1)
		{
			next if $i =~ /^\s*-*$/;
			next if !exists $acc{$i} or @tmp < 1;
			push @{$acc2go{$i}}, @tmp;
		}
	}
	if ($id2)
	{
		$id2 =~ s/\s//g;
		my @id2 = split /;/, $id2;
		foreach my $i (@id2)
		{
			next if $i =~ /^\s*-*$/; 
			next if !exists $acc{$i} or @tmp < 1;
			push @{$acc2go{$i}}, @tmp;
		}
	}
}
close IN;

open OUT, "> $ARGV[3]" or die $!;
foreach my $i (sort keys %hash)
{
	my @go;
	foreach my $acc (@{$hash{$i}})
	{
		next if !exists $acc2go{$acc};
		push @go, @{$acc2go{$acc}};
	}
	my %tmp;
	@go = grep { ++$tmp{$_} < 2 } @go;
	print OUT join("\t", $i,@go)."\n";
}
close OUT;
