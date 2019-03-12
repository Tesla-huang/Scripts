#!/usr/bin/env perl

# id change to rna id, and the trans_acc as the added attri
# always, locus is the unique id.

use utf8;
use warnings;
use strict;

die "Usage: perl $0 <gff> <out.utr.gff>\n" if @ARGV != 2;

my ($gff, $out) = @ARGV;

my (%rnas, %strand, %chr, %rna2trans, %rna2gn);

open GFF, "$gff" or die $!;
while (<GFF>)
{
    next if (/^#/ or /^\s*$/);
    chomp;
    my ($chr, $source, $feature, $start, $end, $score, $strand, $frame, $attri) = split /\t/;
    next unless ($feature =~ /exon/i or $feature =~ /CDS/i);
    $feature = uc($feature);
    my ($rna_id) = $attri =~ /Parent=([^;]+);*?/;
    if ($feature eq "EXON")
    {
        my ($trans_id) = $attri =~ /transcript_id=([^;]+);*?/;
        my ($gene_name) = $attri =~ /gene=([^;]+);*?/;
        $trans_id = "-" unless ($trans_id);
        $gene_name = "-" unless ($gene_name);
        $rna2trans{$rna_id} = $trans_id;
        $rna2gn{$rna_id} = $gene_name;
    }
    push @{$rnas{$rna_id}{$feature}}, $start, $end;
    $strand{$rna_id} = $strand;
    $chr{$rna_id} = $chr;
}
close GFF;

open OUT, "> $out" or die $!;
open ERR, "> $out.err" or die $!;
for my $rna (sort keys %chr)
{
    if (exists $rnas{$rna}{CDS})
    {
        if (!exists $rnas{$rna}{EXON})
        {
            print ERR "$rna	noExon\n";
        }
        else
        {
            my @cds = sort {$a <=> $b} @{$rnas{$rna}{CDS}};
            my @exon = sort {$a <=> $b} @{$rnas{$rna}{EXON}};
            if ($cds[0] < $exon[0] or $cds[$#cds] > $exon[$#exon])
            {
                print ERR "$rna	CDSoutofEXONregions\n";
                next;
            }
            else
            {
                my @region = (@{$rnas{$rna}{CDS}}, @{$rnas{$rna}{EXON}});
                @region = sort {$a <=> $b} @region;
                my $length = $region[$#region] - $region[0] + 1;
                my $seq = "i"x$length;
                my $cds_num = (scalar @{$rnas{$rna}{CDS}} ) / 2;
                my $exon_num = (scalar @{$rnas{$rna}{EXON}}) / 2;
                for my $e (1 .. $exon_num)
                {
                    my $e_s = ${$rnas{$rna}{EXON}}[2 * $e - 2];
                    my $e_e = ${$rnas{$rna}{EXON}}[2 * $e - 1];
                    my $e_len = $e_e - $e_s + 1;
                    my $e_str = "u"x$e_len;
                    my $offset = $e_s - $region[0];
                    substr($seq, $offset, $e_len, $e_str);
                }
                for my $c (1 .. $cds_num)
                {
                    my $c_s = ${$rnas{$rna}{CDS}}[2 * $c - 2];
                    my $c_e = ${$rnas{$rna}{CDS}}[2 * $c - 1];
                    my $c_len = $c_e - $c_s + 1;
                    my $c_str = "c"x$c_len;
                    my $offset = $c_s - $region[0];
                    substr($seq, $offset, $c_len, $c_str);
                }
                my @utrs;
                my @utrseq;
                while ($seq =~ /(u[iu]+u)/g)
                {
                    my $utr = $1;
                    my $utr_e = pos($seq);
                    my $utr_s = $utr_e - length($utr) + 1;
                    push @utrs, "$utr_s:$utr_e";
                    push @utrseq, $utr;
                }
                if (@utrs)
                {
                    for my $i (0 .. $#utrs)
                    {
                        my ($u_s, $u_e) = $utrs[$i] =~ /(\d+):(\d+)/;
                        $u_s += $region[0] - 1;
                        $u_e += $region[0] - 1;
                        my $source = "other_UTR";
                        if ($strand{$rna} eq "-")
                        {
                            if ($u_s == $region[0])
                            {
                                $source = "3_UTR";
                            }
                            elsif ($u_e == $region[$#region])
                            {
                                $source = "5_UTR";
                            }
                        }
                        else
                        {
                            if ($u_s == $region[0])
                            {
                                $source = "5_UTR";
                            }
                            elsif ($u_e == $region[$#region])
                            {
                                $source = "3_UTR";
                            }
                        }
                        if ($utrseq[$i] =~ /i/)
                        {
                            while ($utrseq[$i] =~ /(u+)/g)
                            {
                                my $splice = $1;
                                my $splice_e = pos($utrseq[$i]) + $u_s - 1;
                                my $splice_s = $splice_e - length($splice) + 1;
                                print OUT "$chr{$rna}\t$source\texon\t$splice_s\t$splice_e\t.\t$strand{$rna}\t.\ttranscript_id \"$rna\_$source\"; gene_id \"$rna2trans{$rna}\"; gene_name \"$rna2gn{$rna}\";\n";
                            }
                        }
                        else
                        {
                            print OUT "$chr{$rna}\t$source\texon\t$u_s\t$u_e\t.\t$strand{$rna}\t.\ttranscript_id \"$rna\_$source\"; gene_id \"$rna2trans{$rna}\"; gene_name \"$rna2gn{$rna}\";\n";
                        }
                    }
                }
                else
                {
                    print ERR "$rna	noUTRs\n";
                }
            }
        }
    }
    else
    {
        print ERR "$rna	noCDS\n";
    }
}
close OUT;
close ERR;
