#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

die "Usage: perl $0 <gtf> <list> <trans|gene> <out>\n" if @ARGV != 4;

my ($gtf, $list, $type, $out) = @ARGV;

#transcript_id "ENSSSCT00000004434"; gene_name "ERMARD"; gene_id "ENSSSCG00000004010";
my $symbol = "xxx";
if ($type eq "trans")
{
    $symbol = "transcript_id";
}
elsif ($type eq "gene")
{
    $symbol = "gene_id";
}
else
{
    die "the $type(\$type) is unsupported!!!\n";
}

open LS, "$list" or die $!;
my %list;
while (<LS>)
{
    chomp;
    my @tmp = split /\t/, $_;
    $list{$tmp[0]} = 1;
}
close LS;

open OUT, "> $out" or die $!;
open GTF, "$gtf" or die $!;
while (<GTF>)
{
    chomp;
    my ($chr, $source, $feature, $start, $end, $score, $strand, $frame, $attri) = split /\t/, $_;
    my ($id) = $attri =~ /$symbol\s*"([^;]+)"\s*;/;
    if (exists $list{$id})
    {
        print OUT "$_\n";
    }
}
close GTF;
close OUT;
