#!/usr/bin/perl -w

use strict;
use utf8;

die "Usage: perl $0 <list> <id.col> <add_table> <table.id.col>\nstdout\n" if (@ARGV != 4);

my $list = shift;
my $idcol = shift;
$idcol--;
my $table = shift;
my $tidcol = shift;
$tidcol--;

my %hash;

open IN, "$table" or die $!;
my $thead = <IN>;
chomp($thead);
my @thead = split /\t/, $thead;
my $empty = "\t-"x(scalar @thead);
$thead = "\t".$thead;
while (<IN>){
	chomp;
	my @tmp = split /\t/, $_;
	my $id = $tmp[$tidcol];
	$hash{$id} = $_;
}
close IN;

open IN, "$list" or die $!;
my $head = <IN>;
chomp($head);
$head .= $thead;
print "$head\n";
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	my $id = $tmp[$idcol];
	if (exists $hash{$id})
	{
		print "$_\t$hash{$id}\n";
	}
	else
	{
		print $_.$empty."\n";
	}
}
close IN;
