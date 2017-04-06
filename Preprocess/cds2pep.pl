#! /usr/bin/perl
use strict;
use utf8;
use warnings;
use Bio::SeqIO;

die"perl $0 <in.fa> <out.fa>\n" unless(@ARGV eq 2);

sub TranslateDNAFile(){
	my ($infile, $outfile) = @_;
	my $in = Bio::SeqIO->new(-file=>"< $infile",-format=>"fasta");
	my $out = Bio::SeqIO->new(-file=>"> $outfile", -format=>"fasta");
	while (my $seq = $in->next_seq()){
		$out->write_seq($seq->translate);
	}
}

&TranslateDNAFile($ARGV[0], $ARGV[1]);
