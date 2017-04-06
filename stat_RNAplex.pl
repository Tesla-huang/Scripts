#!/usr/bin/perl -w

use strict;
use utf8;

open IN, "$ARGV[0]" or die $!;

while (<IN>) {
	my $line1 = $_;
	my $line2 = <IN>;
	<IN>;
	<IN>;
	chomp($line1);
	chomp($line2);
	my @tmp = split /\s+/, $line2;
	my $energy = pop(@tmp);
	$line2 = join("\t",@tmp);
	($energy) = $energy =~ /\((\S+)\)/;
	print "$line1\t$line2\t$energy\n";
}
