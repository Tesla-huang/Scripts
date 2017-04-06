#!/usr/bin/perl -w 

use strict;

die "Usage: perl $0 <filexp> <threshold>" if (@ARGV != 2);

open IN, "$ARGV[0]" or die $!;
my $thr = $ARGV[1];

<IN>;
my $all = 0;
my $trash = 0;
while (<IN>) {
	chomp;
	my @tmp = split /\t/, $_;
	my $id = shift(@tmp);
	my $sca = scalar(@tmp);
	my $do = 0;
	$all ++;
	@tmp = sort {$b <=> $a} @tmp;
	if ($tmp[0] <= $thr) {
		$trash ++;
	}else{
		print "$_\n";
	}
}

my $rate = ($trash/$all);
print STDERR "$rate\n";
