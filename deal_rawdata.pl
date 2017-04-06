#!/usr/bin/perl -w

use strict;
use utf8;
use Cwd 'abs_path';

die "Usage: perl $0 <directory> <depth> <read_type>\n" if @ARGV != 3;

my $depth = $ARGV[1];
my $char = "/*"x$depth;
my $type = $ARGV[2];
my $direct = abs_path($ARGV[0]);
$direct .= $char.".gz";

open IN, "ls $direct | " or die $!;
my @tmp = <IN>;
@tmp = sort(@tmp);
if ($type =~ /pe/i) {
	for (my $i = 0 ; $i < scalar(@tmp)/2 ; $i++){
		my $a = $i*2;
		my $id = (split /\//, $tmp[$a])[-1];
		$id  = (split /_/, $id)[0];
		chomp($id);
		chomp($tmp[$a]);
		chomp($tmp[$a+1]);
		print "sample          := $id : $tmp[$a] $tmp[$a+1]\n";
	}
}else{
	for (my $i = 0; $i < scalar(@tmp) ; $i++) {
		my $id = (split /\//, $tmp[$i])[-1];
		$id = (split /_/, $id)[0];
		chomp($id);
		chomp($tmp[$i]);
		print "sample          := $id : $tmp[$i]\n";
	}
}
