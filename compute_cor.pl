#!/usr/bin/perl -w

use strict;
use lib "/home/linyifan/bio/perl5lib/blib/lib";
use Math::NumberCruncher;

die "usage: perl $0 <list(2cols)> <exp.table>\noutput:stdout\n" if (@ARGV != 2);

open EX, "$ARGV[1]" or die $!;

my %hash;

while (<EX>) {
	chomp;
	my @tmp = split /\t/, $_, 2;
	$hash{$tmp[0]} = $tmp[1];
}
close EX;

open IN, "$ARGV[0]" or die $!;

while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	if (exists $hash{$tmp[0]} && exists $hash{$tmp[1]}) {
		my @a = split /\t/, $hash{$tmp[0]};
		my @b = split /\t/, $hash{$tmp[1]};
		my $cor = Math::NumberCruncher::Correlation(\@a, \@b);
		print "$tmp[0]\t$tmp[1]\t$cor\n";
	}else{
		next;
	}
}
close IN;
