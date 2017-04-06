#!usr/bin/perl -w
use strict;

my $list=shift;
my $file=shift;
my $row=shift;
my %hash;
open IN,$list or die $!;
while (<IN>)
{
	chomp;
	my @a=split (/\t/,$_,2);
	$hash{$a[0]}=$a[1];
}
close IN;

open IN,$file or die $!;
while (<IN>)
{
	chomp;
	my @a=split /\t/,$_;
	if (exists $hash{$a[$row-1]})
	{
		print "$_\t$hash{$a[$row-1]}\n";
	}
	else
	{
		print "$_\t-\n";
	}
}
close IN;
