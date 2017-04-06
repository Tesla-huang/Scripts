#!/usr/bin/env perl

#=head1 Name
#=head1 Introduction
#=head1 Author & Email
#=head1 Options
#=head1 Example
#=cut

use warnings;
use strict;
die "Usage: perl $0 <*.desc> <t/g> <out>\n" if @ARGV != 3;

open IN, "$ARGV[0]" or die $!;

<IN>;
my %gene;
my %exists;
open OUT, "> $ARGV[2]" or die $!;
if ($ARGV[1] eq "t")
{
	while (<IN>)
	{
		chomp;
		my @tmp = split /\t/, $_;
		print OUT "$tmp[0]\t$tmp[2]\n";
	}
}
else
{
	while (<IN>)
	{
		chomp;
		my @tmp = split /\t/, $_;
		if ($tmp[3] ne "-" and !exists $exists{$tmp[1]})
		{
			print OUT "$tmp[1]\t$tmp[3]\n";
			$exists{$tmp[1]} = 1;
		}
		else
		{
			next if ($tmp[2] eq "-");
			push @{$gene{$tmp[1]}}, $tmp[2];
		}
	}
	foreach my $g (keys %gene)
	{
		if (!exists $exists{$g})
		{
			print OUT "$g\t$gene{$g}[0]\n";
			$exists{$g} = 1;
		}
	}
}
close IN;
close OUT;
