#!/usr/bin/perl -w

use strict;
use utf8;
#use lib "/home/linyifan/bio/perl5lib/blib/lib";
use Excel::Writer::XLSX;

die "Usage: perl $0 <input>\n" if (@ARGV != 1);

my $file = shift(@ARGV);


my $output = $file;
$output =~ s/\.xls$//;
$output =~ s/$/.xlsx/;

my $book = Excel::Writer::XLSX->new($output);
my $sheet = $book ->add_worksheet();

open IN, "$file" or die $!;
while (<IN>) {
	chomp;
	my @xls = split /\t/, $_;
	for my $i (0..$#xls) {
		$sheet ->write($.-1,$i,$xls[$i]);
	}
}

$book ->close();
