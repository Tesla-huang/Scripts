#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

die "Usage: perl $0 <head[0|1]> <snp.avinput> <new.pos>\n" if @ARGV !=3;

my ($head, $avinput, $pos) = @ARGV;
my $h = "$avinput.h";
if ($head == 1) {
    `head -n 1 $avinput > $avinput.h`;
    `sed 1d $avinput > $avinput.mid`;
}
`sort -k1,1 -k2,2g $avinput.mid > $avinput.in`;
my $in = "$avinput.in";

my (%st_arr, %start, %id_st);

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

open IN, "$in" or die $!;
open OUT, "> $avinput.recover"  or die $!;
while (<IN>) {
    my @tmp = split /\t/, $_;
    if (!exists $pos{$tmp[0]}) {
        print OUT $_;
    }else{
HERE:   for my $s (sort {$a <=> $b} keys %{$pos{$tmp[0]}})
        {
            if ($tmp[1] >= $s and $tmp[2] >= $s)
            {
                for my $e (sort {$a <=> $b} keys %{$pos{$tmp[0]}{$s}})
                {
                    if ($tmp[1] <= $e and $tmp[2] <= $e)
                    {
                        my ($ori, $os, $oe) = $pos{$tmp[0]}{$s}{$e} =~ /^([^=]+)=([^=]+)=([^=]+)$/;
                        $tmp[0] = $ori;
                        $tmp[1] = $tmp[1] - $s + $os;
                        $tmp[2] = $tmp[2] - $s + $os;
                        last HERE;
                    }
                }
            }
        }
        print OUT join("\t", @tmp);
    }
}
close IN;
`cat $avinput.h $avinput.recover > $avinput.done`;
