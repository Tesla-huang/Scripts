#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

die "Usage: perl $0 <list> <table> <head[0|1]> <out>\n" if @ARGV != 4;

my ($list, $table, $head, $out) = @ARGV;

open LIST, "$list" or die $!;
my @list;
my %list;
while (<LIST>)
{
    chomp;
    my ($id, $tmp) = split /\s+/, $_, 2;
    push @list, $id;
    $list{$id} = "xxx\n";
}
close LIST;

open TAB, "$table" or die $!;
if ($head == 1)
{
    $head = <TAB>;
}
while (<TAB>)
{
    my ($id, $tmp) = split /\s+/, $_, 2;
    if (exists $list{$id})
    {
        $list{$id} = $tmp;
    }
}
close TAB;

open OUT, "> $out" or die $!;
print OUT "$head" if ($head ne "0");
for my $id (@list)
{
    print OUT "$id\t$list{$id}";
}
close OUT;
