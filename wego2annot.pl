#! /usr/bin/perl -w
use utf8;
use strict;

open WEGO , '<' , $ARGV[0];

my %wegolist;

while (my $text = <WEGO>){
	$text =~ s/\s+$//;
	my @go_num = split /\t/ , $text;
	my $geneid = shift(@go_num);
	my $i = 0;
	foreach (@go_num){
		push (@{$wegolist{$geneid}}, $_);
	}
}

my $out = $ARGV[0];
$out =~ s/wego$/annot/;

open ANNOT , '>' , "$out";

foreach my $geneid (sort keys %wegolist){
	foreach (@{$wegolist{$geneid}}){
		print ANNOT "$geneid\t$_\n";
	}
}
