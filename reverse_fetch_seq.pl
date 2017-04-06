#!/usr/bin/perl -w

use strict;
use utf8;

open IN, "$ARGV[0]" or die $!;
local $/ = "\n>";
while (<IN>) {
	chomp;
	s/^>//;
	my $id1 = $_;
	my $line2 = <IN>;
	chomp($line2);
	my @tmp = split /\n/, $line2;
	my $seq = $tmp[1];
	my $relate = $tmp[2];
	my @seq = split /&/, $seq;
	my @relate = split /&/, $relate;
	my @seq_2 = split //, $seq[1];
	@seq_2 = reverse(@seq_2);
	$seq[1] = join("", @seq_2);
	my @relate_2 = split //, $relate[1];
	@relate_2 = reverse(@relate_2);
	$relate[1] = join("", @relate_2);
	$relate[0] =~ s/\(/|/g;
	$relate[1] =~ s/\)/|/g;
	my @line1 = split //, $relate[0];
	my @line2 = split //, $relate[1];
	my @seq1 = split //, $seq[0];
	my @seq2 = split //, $seq[1];
	my @ref;
	for(my $i = 0; $i < scalar(@seq1) + scalar(@seq2); $i++){
		unless (defined $seq1[$i] && defined $seq2[$i]){
			last;
		}else{
			if ($line1[$i] eq $line2[$i]) {
				next;
			}else{
				if ($line1[$i] eq "|") {
					splice(@seq1,$i,0,"-");
					splice(@line1,$i,0,"-");
				}else{
					splice(@seq2,$i,0,"-");
					splice(@line2,$i,0,"-");
				}
			}
		}
	}
	$relate[0] = join("", @line1);
	$relate[1] = join("", @line2);
	$seq[0] = join("", @seq1);
	$seq[1] = join("", @seq2);
	open OUT, ">$id1\_$tmp[0].txt" or die $!;
	print ">$id1\n>$tmp[0]\n5' $seq[0] 3'\n   $relate[0]   \n   $relate[1]   \n3' $seq[1] 5'\n\n";
	close OUT;
}
