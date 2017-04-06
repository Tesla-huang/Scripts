#!perl
use warnings;
use strict;

die "perl $0 <fasta> <outprefix>\n" if @ARGV != 2;

open FA, $ARGV[0] or die $!;
open OUT, "> $ARGV[1].hdrs" or die $!;
$/ = "\n>";
while(<FA>)
{
	chomp;
	s/>//;
	my @lines = split /\n/;
	my @head = split /\s+/, $lines[0];
	my $str = join "", @lines[1..$#lines];
	my $sumLen = length($str);
	my $NLen = $str =~ tr/Nn/Nn/;
	my $nonNLen = $sumLen - $NLen;
	print OUT ">$head[0] /len=$sumLen /nonNlen=$nonNLen\n";
}
