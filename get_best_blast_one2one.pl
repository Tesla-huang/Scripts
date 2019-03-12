#! /usr/bin/perl

use utf8;
use strict;
use warnings;

die "Usage: perl $0 <blastresultoutfmt6> <out>\n" if (@ARGV != 2);

my ($in, $out) = @ARGV;

open IN, "$in" or die $!;
open OUT, "> $out" or die $!;
my %first;
my %fst_line;
my %fst_score;

while (<IN>)
{
    chomp;
    my ($query, $subject, $identity, $alignlen, $mismatch, $gap, $qstart, $qend, $sstart, $send, $eval, $bitscore) = split /\t/, $_;
    if (!exists $first{$query} or $bitscore > $fst_score{$query})
    {
        $first{$query} = $subject;
        $fst_line{$query} = $_;
        $fst_score{$query} = $bitscore;
    }
}
close IN;

my %second;
my %final;
my %final_line;
my %final_score;

for my $query (keys %first)
{
    push @{$second{$first{$query}}}, $query;
}

for my $subject (keys %second)
{
    for my $query (@{$second{$subject}})
    {
        if (!exists $final{$subject} or $fst_score{$query} > $final_score{$subject})
        {
            $final{$subject} = $query;
            $final_line{$subject} = $fst_line{$query};
            $final_score{$subject} = $fst_score{$query};
        }
    }
}

for my $subject (keys %final)
{
    print OUT "$final_line{$subject}\n";
}

close OUT;
