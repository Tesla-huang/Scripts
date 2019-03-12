#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

die "Usage: perl $0 <tr.kopath> <gene2longestTr> <out.gene.kopath>\n" if @ARGV != 3;

my ($trko, $tr2gene, $out) = @ARGV;

my %tr2gene;
open TG, "$tr2gene" or die $!;
while (<TG>)
{
    chomp;
    my ($gene, $tr, $tmp) = split /\t/, $_, 3;
    $tr2gene{$tr} = $gene;
}
close TG;

open TK, "$trko" or die $!;
open OUT, "> $out" or die $!;
while (<TK>)
{
    chomp;
    my ($id, $tmp) = split /\t/, $_, 2;
    next unless ($tmp);
    if (exists $tr2gene{$id})
    {
        print OUT "$tr2gene{$id}\t$tmp\n";
    }
}
close TK;
close OUT;
