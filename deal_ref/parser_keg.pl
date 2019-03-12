#!/usr/bin/env perl

#=head1 Name
#=head1 Introduction
#=head1 Author & Email
#       Ivan Lam
#       lamivan.cn@gmail.com
#
#=head1 Parameter
#=head2 Required parameter
#=head2 Optional paramater
#=head1 Example
#=cut

use utf8;
use warnings;
use strict;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;

#die `pod2text $0` unless ($in && $out);
die "Usage: perl $0 <in keg file> <short species name> <out txt>\n" if @ARGV != 3;

my $C_now = "xxx";

my (%pathway, %KID);

my ($keg, $sn, $out) = @ARGV;

open KEG, "$keg" or die $!;
while (<KEG>)
{
    next unless (/^[CD]/);
    chomp;
    if (/^C/)
    {
        my @tmp = split /\s+/, $_, 3;
        $C_now = $tmp[1];
    }
    if (/^D/)
    {
        my ($ncbi, $ec) = split /\t/, $_, 2;
        my @ncbi = split /\s+/, $ncbi, 3;
        my @ec = split /\s+/, $ec , 2;
        my $geneid = $ncbi[1];
        my $kid = $ec[0];
        push @{$pathway{$geneid}}, $C_now;
        $KID{$geneid} = $kid;
    }
}
close KEG;

open OUT, "> $out" or die $!;
for my $geneid (sort keys %KID)
{
    my %tmp;
    my @pathway_now = grep {++$tmp{$_}<2} @{$pathway{$geneid}};
    print OUT "$geneid\t$KID{$geneid}\t".join(",",@pathway_now)."\t$sn:$geneid\n";
}
close OUT;






