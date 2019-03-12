#!/usr/bin/env perl

use warnings;
use strict;
use Bio::SeqIO;

die "Usage: perl $0 <blastresult.outfmt6> <query.fa> <db.fa> <out>\n" if @ARGV != 4;

my ($result, $query, $db, $out) = @ARGV;

my %start;
my %end;

open (RS, "$result") or die $!;
while (<RS>)
{
    chomp;
    my @tmp = split /\t/, $_;
    my ($query, $subject, $qstart, $qend, $sstart, $send) = @tmp[0,1,6,7,8,9];
    if ($sstart > $send)
    {
        ($sstart, $send) = ($send, $sstart);
    }
    push @{$start{$query}{$subject}{$subject}}, $sstart;
    push @{$end{$query}{$subject}{$subject}}, $send;
    push @{$start{$query}{$subject}{$query}}, $qstart;
    push @{$end{$query}{$subject}{$query}}, $qend;
}
close RS;

my %db;

my $db_in = Bio::SeqIO->new(-file => $db, -format => 'Fasta');
while (my $seq = $db_in->next_seq() )
{
    my $len = length($seq->seq);
    $db{$seq->id} = $len;
}

my $query_in = Bio::SeqIO->new(-file => $query, -format => 'Fasta');
while (my $seq = $query_in->next_seq() )
{
    my $len = length($seq->seq);
    $db{$seq->id} = $len;
}

open (OUT, "> $out") or die $!;
for my $query (keys %start)
{
    for my $subject (keys %{$start{$query}})
    {
        my $qalignlen = getalignlen(\@{$start{$query}{$subject}{$query}}, \@{$end{$query}{$subject}{$query}});
        my $qcov = sprintf("%.2f", $qalignlen/$db{$query});
        my $salignlen = getalignlen(\@{$start{$query}{$subject}{$subject}}, \@{$end{$query}{$subject}{$subject}});
        my $scov = sprintf("%.2f", $salignlen/$db{$subject});
        my $q_div_s = sprintf("%.2f", $qalignlen / $salignlen);
        print OUT "$query\t$subject\t$qalignlen\t$qcov\t$salignlen\t$scov\t$q_div_s\n";
    }
}
close OUT;


sub getalignlen
{
    my ($start, $end) = @_;
    my @pos = @{$start};
    my $termi = scalar @pos - 1;
    push @pos, @{$end};
    @pos = sort {$a <=> $b} @pos;
    my $align = "0"x$pos[-1];
    for my $i (0 .. $termi)
    {
        my $dis = $$end[$i] - $$start[$i] + 1;
        my $index = $$start[$i] - 1;
        my $catch = "1"x$dis;
        substr($align, $index, $dis, $catch);
    }
    $align =~ s/0//;
    my $alignlen = length($align);
    return $alignlen;
}
