#!/usr/bin/perl -w

use strict;
use utf8;

open FA, "$ARGV[0]" or die $!;
local $/ = "\n>";
open OUT, "> $ARGV[0].txt" or die $!;
while (<FA>) {
	chomp;
	s/^>//;
	my @tmp = split /\n/, $_;
	my $id = shift(@tmp);
	$id = (split /\s+/, $id)[0];
	my $text = join("", @tmp);
	print OUT "$id\t$text\n";
}
close OUT;
