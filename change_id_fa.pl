#! /usr/bin/perl

use utf8;
use strict;
use warnings;
#use Getopt::Long;
#use Bio::SeqIO;
#use Bio::Seq;
#use List::Util qw/sum min max/;
#use File::Basename qw/basename dirname/;
#use File::Spec::Functions qw/rel2abs/;
#use FindBin qw/$Bin $Script/;
#use lib $Bin;

die "perl $0 <annot> <tr2gene> \n" unless(@ARGV eq 2);

open IN, "$ARGV[0]" or die $!;
open ID, "$ARGV[1]" or die $!;

my %hash;

while (<ID>) {
	chomp;
	my @tmp = split /\t/, $_;
	$hash{$tmp[0]} = $tmp[1];
}
close ID;

while (<IN>) {
	if (/^>/) {
		my ($id) = $_ =~ /^>(\S+)/;
		if (!exists $hash{$id}) {
			print "$_";
		}else{
			print ">$hash{$id}\n";
		}
	}else{
		print "$_";
	}
}
