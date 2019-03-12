#!/usr/bin/env perl

use utf8;
use warnings;
use strict;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;

die "Usage: perl $0 <entrez.kopath> <geneid2entrezid> <out>\n" if @ARGV != 3;

my ($entrez, $gene, $out) = @ARGV;

my %db;
open EN, "$entrez" or die $!;
while (<EN>)
{
    chomp;
    my ($id , $line) = split /\t/, $_, 2;
    $db{$id} = $line;
}
close EN;


open LIST, "$gene" or die $!;
open OUT, "> $out" or die $!;
while (<LIST>)
{
    chomp;
    my ($geneid, $entrezid) = split /\t/, $_;
    if ($entrezid)
    {
        if (exists $db{$entrezid})
        {
            print OUT "$geneid\t$db{$entrezid}\n";
        }
        else
        {
            next;
        }
    }
    else
    {
        next;
    }
}
close LIST;
