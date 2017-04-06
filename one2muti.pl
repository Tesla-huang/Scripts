#!/usr/bin/perl -w

use strict;
use utf8;

die "Usage: perl $0 <fa>\nstdout\n" if (@ARGV != 1);

open FA, "$ARGV[0]" or die $!;

local $/ = "\n>";

while (<FA>) {
	s/^>//;
	chomp;
	my @tmp = split /\n/, $_, 2;
	$tmp[1] =~ s/\s//g;
	print ">$tmp[0]\n";
	my $len = length($tmp[1]);
	my $cnt = int($len/70);
	for (my $i = 0; $i < $cnt; $i ++) {
		my ($text) = $tmp[1] =~ /^(\S{70})/;
		$tmp[1] =~ s/^\S{70}//;
		print "$text\n";
	}
	print "$tmp[1]\n";
}
