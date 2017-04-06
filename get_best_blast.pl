#! /usr/bin/perl

use utf8;
use strict;
use warnings;
#use Getopt::Long;
#use Bio::SeqIO;
#use Bio::Seq;
#use List::Util qw/sum min max/;
#use List::MoreUtils qw/uniq/;
#use File::Basename qw/basename dirname/;
#use File::Spec::Functions qw/rel2abs/;
#use FindBin qw/$Bin $Script/;
#use lib $Bin;

#die "perl $0 <arg1> <arg2> <arg3>\n" unless(@ARGV eq 3);

die "Usage: perl $0 <in1..inn\n" if (@ARGV < 1);


foreach my $i (@ARGV) {
	open IN, "$i" or die $!;
	my $out = $i;
	my %hash;
	$out =~ s/\.xls$//;
	$out =~ s/$/.best.xls/;
	open OUT, "> $out" or die $!;
	while (<IN>) {
		my @tmp = split /\t/, $_, 2;
		if (!exists $hash{$tmp[0]}) {
			print OUT "$_";
			$hash{$tmp[0]} = 1;
		}else{
			next;
		}
	}
	close IN;
	close OUT;
	undef %hash;
}
