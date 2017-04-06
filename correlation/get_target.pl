#!usr/bin/perl -w
use strict;

my %list;
open IN,$ARGV[0] or die $!;
while (<IN>)
{
	chomp;
	$list{$_}=1;
}
close IN;

open IN,$ARGV[1] or die $!;
while (<IN>)
{	
	chomp;
	my @a=split /\t/,$_;
	if (exists $list{"$a[0]\t$a[1]"})
	{
		print "$_\n";
}
}
