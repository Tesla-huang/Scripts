#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

die "Usage: perl $0 <list> <in> <out>\n" if @ARGV != 3;

my %list;

open LS, "$ARGV[0]" or die $!;
while (<LS>)
{
    chomp;
    my @tmp = split /\t/, $_;
    my $id = "$tmp[0]\t$tmp[1]";
    $list{$id} = 1;
}
close LS;

open OUT, "> $ARGV[2]" or die $!;
open IN, "$ARGV[1]" or die $!;
while (<IN>)
{
    chomp;
    my @tmp = split /\t/, $_;
    my $id = "$tmp[0]\t$tmp[1]";
    if (exists $list{$id})
    {
        print OUT "$_\n";
    }
}

