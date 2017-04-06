#!/usr/bin/perl -w

use strict;
use utf8;

die "Usage: perl $0 <ensembl.gtf> stdout\n" if (@ARGV != 1);

open IN, "$ARGV[0]" or die $!;

while (<IN>) {
	if (/^#/) {
		next;
	}else{
		chomp;
		my @tmp = split /\t/, $_;
		if ($tmp[2] eq "exon") {
		my ($gene_id) = $tmp[8] =~ /gene_id "(\S+)";/;
		my ($trans_type) = $tmp[8] =~ /transcript_biotype "(\S+)";/;
		my ($gene_type) = $tmp[8] =~ /gene_biotype "([^;]+)";/;
		my ($trans_id) = $tmp[8] =~ /transcript_id "(\S+)";/;
		my $gene_name = "unknown";
		($gene_name) = $tmp[8] =~ /gene_name "(.+?)";/ if ($tmp[8] =~ /gene_name/);
		print "$tmp[0]\t$gene_id\t$trans_id\t$gene_name\t$gene_type\t$trans_type\n";
		}else{
			next;
		}
	}
}
