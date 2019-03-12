#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

die "Usage: perl $0 <tr2gene> <tr.wego> <out.gene.wego>\n" if @ARGV != 3;

my ($tr2gene, $trwego, $out) = @ARGV;

open TG, "$tr2gene" or die $!;
my %gene2tr;
while (<TG>)
{
    chomp;
    my ($tr, $gene, $tmp) = split /\t/, $_, 3;
    push @{$gene2tr{$gene}}, $tr;
}
close TG;

my %trgo;
open WG, "$trwego" or die $!;
while (<WG>)
{
    chomp;
    my ($tr, @gos) = split /\t/, $_;
    $trgo{$tr} = \@gos;
}
close WG;

open OUT, "> $out" or die $!;
for my $gene (sort keys %gene2tr)
{
    my @go;
    for my $tr (@{$gene2tr{$gene}})
    {
        if (exists $trgo{$tr})
        {
            push @go, @{$trgo{$tr}};
        }
    }
    if (scalar @go > 0)
    {
        my %tmp;
        @go = grep {++$tmp{$_}<2} @go;
        print OUT "$gene\t".join("\t", @go)."\n";
    }
}
close OUT;
