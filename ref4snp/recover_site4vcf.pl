#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use File::Spec::Functions qw/rel2abs/;

die "Usage: perl $0 <Sample_id.vcf> <new.pos> <ref.fa> <ref.dict>\n" if @ARGV !=4;

my $picard = "/Bio/Bin/picard.jar";
die "picard is not exists in this path $picard!\n" if (!-s $picard);
my ($vcf, $pos, $ref, $dict) = @ARGV;
$ref = rel2abs($ref);
my $fai = $ref.".fai";
if (!-s "$fai")
{
    print STDERR "the $fai is not exists, generating now...\n";
    `samtools faidx $ref`;
    die "the fai is not exists or generating failed!\n" if (!-s $fai);
}

open FAI, "$fai" or die $!;
my %len;
while(<FAI>)
{
    chomp;
    my ($chr, $len, $tmp) = split /\s+/, $_, 3;
    $len{$chr} = $len;
}
close FAI;

my @order;
open DIC, "$dict" or die $!;
while (<DIC>)
{
    next unless (/^\@SQ/);
    my ($name) = $_ =~ /SN:(\S+)\s*/;
    push @order, $name;
}
close DIC;

open POS, "$pos" or die $!;
my %pos;
while (<POS>)
{
    chomp;
# $ori: original_id, $os: original_start, $oe: original_end, $new: new_id, $ns: new_start, $ne: new_end;
    my ($ori, $os, $oe, $new, $ns, $ne) = split /\t/, $_;
    $pos{$new}{$ns}{$ne} = "$ori=$os=$oe";
}
close POS;

open IN, "$vcf" or die $!;
my $out_tmp = $vcf;
$out_tmp =~ s/vcf$/tmp.vcf/;
my @head;
my $head;
open OUT, "> $out_tmp" or die $!;
while (<IN>)
{
    if (/^##/)
    {
        if (/^##contig=/)
        {
            next;
        }
        elsif (/^##reference=/)
        {
            next;
        }
        else
        {
            push @head, $_;
        }
    }
    elsif (/^#CHROM/)
    {
        $head = "$_";
        print OUT join("", @head);
        for my $i (@order)
        {
            print OUT "##contig=<ID=$i,length=$len{$i}>\n";
        }
        print OUT "##reference=file://$ref\n";
        print OUT $head;
    }
    else
    {
        chomp;
        my ($chr, $pos, $id, $refbase, $altbase, $qual, $filter, $info, $format, $depth) = split /\t/, $_;
        if (exists $len{$chr})
        {
            print OUT "$_\n";
        }
        else
        {
HERE:       for my $s (sort {$a <=> $b} keys %{$pos{$chr}})
            {
                if ($pos >= $s)
                {
                    for my $e (sort {$a <=> $b} keys %{$pos{$chr}{$s}})
                    {
                        if ($pos <= $e)
                        {
                            my ($ori, $os, $oe) = $pos{$chr}{$s}{$e} =~ /^([^=]+)=([^=]+)=([^=]+)$/;
                            $chr = $ori;
                            if ($info =~ /END=/)
                            {
                                my ($end) = $info =~ /END=(\d+)/;
                                $end = $end - $s + $os;
                                $info = "END=$end";
                            }
                            $pos = $pos - $s + $os;
                            last HERE;
                        }
                    }
                }
            }
            print OUT "$chr\t$pos\t$id\t$refbase\t$altbase\t$qual\t$filter\t$info\t$format\t$depth\n";
        }
    }
}
close OUT;
close IN;
`mv $vcf.idx $vcf.idx.bak`;
`mv $vcf $vcf.bak`;
`java -jar /Bio/Bin/picard.jar SortVcf I=$out_tmp O=$vcf`;
`rm -rf $vcf.idx`;
