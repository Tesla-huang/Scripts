#!/usr/bin/env perl

use warnings;
use strict;
die "Usage: perl $0 <in.bam> <new.dict> <new.pos> <outprefix>\n" if @ARGV != 4;

my ($in, $dict, $pos, $out) = @ARGV;

my $bak = $in;
$bak =~ s/\.bam$/.bak.bam/;
`mv $in $bak`;

my %pos;
open POS, "$pos" or die $!;
while (<POS>)
{
    chomp;
# $ori: original_id, $os: original_start, $oe: original_end, $new: new_id, $ns: new_start, $ne: new_end;
    my ($ori, $os, $oe, $new, $ns, $ne) = split /\t/, $_;
    $pos{$ori}{$os}{$oe} = "$new=$ns=$ne";
}
close POS;

open OUT, "> $out.sam" or die $!;
my $head = `samtools view -H $bak`;
chomp($head);
my @head = split /\n/, $head;
my $HD = $head[0];
$HD =~ s/SO:\w+/SO:unsorted/;
my $RG = $head[1];
my $PG = $head[-1];
open DICT, "$dict" or die $!;
my @SQ;
while (<DICT>)
{
    next unless (/\@SQ/);
    chomp;
    my @tmp = split /\t/, $_;
    push @SQ, join("\t", @tmp[0 .. 2]);
}
close DICT;

print OUT "$HD\n$RG\n";
print OUT join("\n", @SQ)."\n";
print OUT "$PG\n";

open IN, "samtools view $bak |" or die $!;
while (<IN>)
{
    chomp;
    my @tmp = split /\t/, $_;
    if ($tmp[2] eq "*")
    {
        print OUT $_."\n";
    }
    else
    {
        my $first = $tmp[2];
        if (exists $pos{$first})
        {
HERE3:      for my $s (sort {$a <=> $b} keys %{$pos{$first}})
            {
                if ($tmp[3] >= $s)
                {
                    for my $e (sort {$a <=> $b} keys %{$pos{$first}{$s}})
                    {
                        if ($tmp[3] <= $e)
                        {
                            my ($new, $ns, $ne) = $pos{$first}{$s}{$e} =~ /^([^=]+)=([^=]+)=([^=]+)$/;
                            $tmp[2] = $new;
                            $tmp[3] = $tmp[3] - $s + $ns;
                            last HERE3;
                        }
                    }
                }
            }
        }

        my $next = $tmp[6];
        $next = $first if ($tmp[6] eq "=");
        unless ($next eq "*")
        {
            if (exists $pos{$next})
            {
HERE7:          for my $s (sort {$a <=> $b} keys %{$pos{$next}})
                {
                    if ($tmp[7] >= $s)
                    {
                        for my $e (sort {$a <=> $b} keys %{$pos{$next}{$s}})
                        {
                            if ($tmp[7] <= $e)
                            {
                                my ($new, $ns, $ne) = $pos{$next}{$s}{$e} =~ /^([^=]+)=([^=]+)=([^=]+)$/;
                                $tmp[6] = $new;
                                $tmp[6] = "=" if ($tmp[2] eq $tmp[6]);
                                $tmp[7] = $tmp[7] - $s + $ns;
                                last HERE7;
                            }
                        }
                    }
                }
            }
        }
        print OUT join("\t", @tmp)."\n";
    }
}
close IN;
close OUT;
`samtools view -bS $out.sam -o $out.bam`;
`samtools sort --threads 4 -o $out.sort.bam -T $out $out.bam `;
`mv -f $out.sort.bam $out.bam`;
`rm -rf $out.sam`;
