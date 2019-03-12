#!/usr/bin/env perl

use warnings;
use strict;

die "Usage: perl $0 <id2proacc> <idmap> <out>\n" if @ARGV != 3;

my %hash;
my %acc;
my %acc2go;

open IN, "$ARGV[0]" or die $!;
while (<IN>)
{
	next if (/^#/);
	chomp;
	my @tmp = split /\t/, $_;
	next if $tmp[0] =~ /^\s*-*$/ or $tmp[1] =~ /^\s*-*$/;
	push @{$hash{$tmp[0]}}, $tmp[1];
	$acc{$tmp[1]} = 1;
}
close IN;

open IN, "$ARGV[1]" or die $!;
while (<IN>)
{
	chomp;
	my @tmp = split /\t/, $_;
	shift @tmp;
	my $id = shift @tmp;
	$id =~ s/\s//g;
	my @id = split /;/, $id;
	foreach my $i (@id)
	{
		next if $i =~ /^\s*-*$/;
		next if !exists $acc{$i} or @tmp < 1;
		push @{$acc2go{$i}}, @tmp;
	}
}
close IN;

open OUT, "> $ARGV[2]" or die $!;
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
