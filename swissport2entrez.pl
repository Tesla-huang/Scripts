#!/usr/bin/env perl

#=head1 Name
#=head1 Introduction
#=head1 Author & Email
#=head1 Options
#=head1 Example
#=cut

use warnings;
use strict;
die "Usage: perl $0 <in> <out>\n" if @ARGV != 2;

my $database = "/home/linyifan/script/idmapping.swissport2entrez";

open IN, "$ARGV[0]" or die $!;

my %list;

while (<IN>)
{
	chomp;
	my $id = (split /\s+/, $_)[0];
	$list{$id} = "-";
}

close IN;

open OUT, "> $ARGV[1]" or die $!;
open IN, "$database" or die $!;

while (<IN>)
{
	my @tmp = split /\t/, $_;
	next unless ($tmp[1]);
	my ($entrez) = $tmp[1] =~ /^(\d+)/;
	if (exists $list{$tmp[0]})
	{
		$list{$tmp[0]} = $entrez;
	}
}
close IN;

foreach my $l (sort keys %list)
{
	print OUT "$l\t$list{$l}\n";
}
close OUT;
