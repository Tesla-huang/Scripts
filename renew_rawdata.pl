#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <rawdata> <type:fq/fq.gz> <compasstype:gz/bz2>\n" if (@ARGV != 3);
my $file = shift(@ARGV);
my $prefix = $file;
$prefix =~ s/fq\S+$/fq.new/;
my $pipein = shift(@ARGV);
my $compass = shift(@ARGV);
if ($pipein =~ /gz$/i) {
	my $tmp = `which gzip`;
	die "Couldnt find gzip!\n" if (undef $tmp);
	$pipein = "gzip -dc";
}elsif ($pipein =~ /bz2$/i){
	my $tmp = `which bzip2`;
	die "Couldnt find bzip2!\n" if (undef $tmp);
	$pipein = "bzip2 -dc";
}else{
	$pipein = "less";
}

if ($compass =~ /gz$/i) {
	my $tmp = `which gzip`;
	die "Couldnt find gzip!\n" if (undef $tmp);
	$compass = "gzip";
	$prefix .= ".gz";
}elsif ($compass =~ /bz2$/i){
	my $tmp = `which bzip2`;
	die "Couldnt find bzip2!\n" if (undef $tmp);
	$compass = "bzip2";
	$prefix .= ".bz2";
}else{
	$compass = "less";
}

open FQ, "$pipein $file |" or die $!;
open OUT, "| $compass > $prefix" or die $!;
while (<FQ>) {
	if ($. % 4 == 1) {
		chomp;
		s/\/\d$//;
		print OUT "$_\n";
	}else{
		print OUT "$_";
	}
}
