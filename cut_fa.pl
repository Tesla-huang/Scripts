#!/usr/bin/perl -w

use strict;

open IN, "$ARGV[0]" or die $!;

my $range = $ARGV[1];
my $overlap = $ARGV[2];

local $/ = "\n>";

while(<IN>){
	chomp;
	s/^>//;
	my @tmp = split /\n/, $_, 2;
	my $id = (split /\s+/, $tmp[0])[0];
	my $seq = $tmp[1];
	$seq =~ s/\n//g;
	my $len = length($seq);
	my $step = int($len/$range) + 1;
	my $long = $range + $overlap;
	for (my $i = 0; $i < $step; $i ++) {
		if ($seq =~ /^\S{$long}/) {
			my ($text) = $seq =~ /^(\S{$long})/;
			$seq =~ s/^\S{$range}//;
			my $start = $i*$range + 1;
			my $end = ($i + 1)*$range + $overlap;
			my $name = $id."_".$start."-".$end;
			print ">$name\n$text\n";
		}else{
			my $text = $seq;
			my $start = $i*$range + 1;
			my $end = $start + length($seq) - 1;
			my $name = $id."_".$start."-".$end;
			print ">$name\n$text\n";
			last;
		}
	}
}
