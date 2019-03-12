#!/usr/bin/env perl

use utf8;
use warnings;
use strict;
use List::Util qw/sum/;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;

die "Usage: perl $0 <indir> <test_read_num> <out.report>\n" if @ARGV != 3;

my ($in, $num, $out) = @ARGV;

my @file = `ls $in/*.gz`;
open OUT, "> $out" or die $!;
print OUT "sample\tmax\tmin\t$num\_avg\tpath\n";
$num = $num * 4;
for my $file (@file)
{
    chomp($file);
    open IN, "gzip -dc $file | head -n $num |" or die $!;
    my $path = rel2abs($file);
    my $sample = basename($file);
    if ($file =~ /_/)
    {
        $sample = (split /_/, $sample, 2)[0];
    }
    else
    {
        $sample = (split /\./, $sample, 2)[0];
    }
    my @length;
    while (<IN>)
    {
        next if ($. %4 != 2);
        chomp($_);
        push @length, length($_);
    }
    close IN;
    @length = sort {$a <=> $b} @length;
    my $avg = sum(@length)/scalar(@length);
    print OUT "$sample\t$length[$#length]\t$length[0]\t$avg\t$path\n";
}
close OUT;
