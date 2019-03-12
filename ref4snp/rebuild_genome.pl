#!/usr/bin/env perl

=head1 Name
        rebuild_genome.pl

=head1 Introduction
        to rebuild the genome sequence, maybe combine or split to adapted
        the GATK coordinate dealing step.

=head1 Author & Email
        Ivan Lam
        lamivan.cn@gmail.com

=head1 Parameter

=head2 Required parameter
        -fa    <strings>   the original genome sequence file
        -gtf   <strings>   the original gene model file
        -op    <strings>   the output files prefix. outputs: new fa, new gtf, old2new pos.

=head2 Optional paramater
        -fai   <strings>   the genome sequence's fai file, if not exists, samtools will generate it.
        -not   <strings>   one colume file to tell the program which chromesome(scaffold)s will not modify.
        -cb    <int>       unit of measurement is Million(M), chromesome(scaffold)'s length less
                           than this paramater set will be combine. (default is 50)
        -cn    <int>       how many Ns will be used to seperate two short sequence. (default is 300)
        -max   <int>       unit of measurement is Million(M), the max length of the pseudo chromesome
                           (default is 300).
        -sp    <int>       unit of measurement is Million(M), chromesome(scaffold)'s length more
                           than this paramater set will be split. (default is 500)

=head1 Example
        perl rebuild_genome.pl -fa test.fa -gtf test.gtf -op new
        perl rebuild_genome.pl -fa tae.fa -gtf tae.gtf -op new -not tae.not_change_chr.list -cb 100 -cn 400 -max 500 -sp 500

=cut

use utf8;
use warnings;
use strict;
use Getopt::Long;
use Bio::SeqIO;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;

my ($fa, $gtf, $cb, $cn, $fai, $max, $sp, $not, $op);
GetOptions(
        "fa=s"    => \$fa,
        "gtf=s"   => \$gtf,
        "cb=i"    => \$cb,
        "cn=i"    => \$cn,
        "max=i"   => \$max,
        "sp=i"    => \$sp,
        "not=s"   => \$not,
        "op=s"    => \$op,
        "fai=s"   => \$fai,
        );

die `pod2text $0` unless ($fa && $gtf && $op);

# checking the programs and parameters

my $picard = "/Bio/Software/Toolset/picard-tools-2.5.0/picard.jar";
die "couldn't find the picard in $picard\n" unless (-s $picard);
my $samtools = `which samtools`;
die "couldn't find samtools in \$PATH!\n" unless ($samtools);
chomp($samtools);

my $flag = 0;
my $wrong = "These problems makes the rebuild_genome.pl die early: \n";

$fa = rel2abs($fa);
$gtf = rel2abs($gtf);
$op = rel2abs($op);
$cb ||= 50;
$cn ||= 300;
$max ||= 300;
$sp ||= 500;
$not ||= "!SKIP!";
$fai ||= "!NO!";


my %check = ("-cb" => $cb,
        "-cn"   => $cn,
        "-max"  => $max,
        "-sp"   => $sp,
        );

unless (-s $fa and -s $gtf)
{
    $flag ++;
    $wrong .= "fa or gtf dose not existsm, please check!\n";
}

unless (-s $fai)
{
    if (-s "$fa.fai")
    {
        $fai = "$fa.fai";
    }
    else
    {
        `$samtools faidx $fa`;
        $fai = "$fa.fai" if (-s "$fa.fai");
    }
}
if ($fai eq "!NO!")
{
    $flag ++;
    $wrong .= "couldn't find the fai file, or creat it failed! $fai \n";
}
if ($not ne "!SKIP!")
{
    unless (-s $not)
    {
        $flag ++;
        $wrong .= "couldn't find the -not file! $not \n";
    }
}

for my $key (keys %check)
{
    if ($check{$key} < 0)
    {
        $flag ++;
        $wrong .= "the $key is < 0, please use another value!\n";
    }
}

die "$wrong" if ($flag > 0);

$cb = $cb * 1000000;
$max = $max * 1000000;
$sp = $sp * 1000000;

# initial input and output files

my $fa_orgin = Bio::SeqIO->new(-file => $fa, -format => 'Fasta');
open NF, "> $op.tmp.fa" or die $!;
open NP, "> $op.pos" or die $!;

# start to rebuild the genome sequence

my %action; ## 0: out, 1: combine, 2: split.
my %length;
if ($not ne "!SKIP!")
{
    open SKIP, "$not" or die $!;
    while (<SKIP>)
    {
        next if (/^#/);
        next if (/^\s*$/);
        my ($chr, $tmp) = split /\s+/, $_, 2;
        $action{$chr} = 0;
    }
    close SKIP;
}
open FAI, "$fai" or die $!;
while (<FAI>)
{
    my ($chr, $len, $tmp) = split /\s+/, $_, 3;
    $length{$chr} = $len;
    next if (exists $action{$chr});
    my $action = $len < $cb ? 1
        : $len <= $sp ? 0
        :               2
        ;
    $action{$chr} = $action;
}
close FAI;

my (%seq4cb, %seq4sp);
while (my $seq = $fa_orgin->next_seq())
{
    if ($action{$seq->id} == 0)
    {
        print NF ">".$seq->id."\n".$seq->seq."\n";
    }
    elsif ($action{$seq->id} == 1)
    {
        $seq4cb{$seq->id} = $seq->seq;
    }
    elsif ($action{$seq->id} == 2)
    {
        $seq4sp{$seq->id} = $seq->seq;
    }
}
undef $fa_orgin;

open GTF, "$gtf" or die $!;
open NG, "> $op.gtf" or die $!;
my %gtf;
while (<GTF>)
{
    next if (/^#/);
    next if (/^\s*$/);
    my ($chr, $tmp) = split /\t/, $_, 2;
    if ($action{$chr} == 0)
    {
        print NG "$_";
    }
    else
    {
        push @{$gtf{$chr}}, $tmp;
    }
}
close GTF;

if (scalar (keys %seq4cb) > 1)
{
    chrcombine($cn, $max, \%seq4cb, \%length);
}
else
{
    for my $chr (keys %seq4cb)
    {
        print NF ">$chr\n$seq4cb{$chr}\n";
    }
}

if (scalar (keys %seq4sp) > 0)
{
    chrsplit($cn, $sp, \%seq4sp, \%length, \%gtf);
}
close NF;
`java -jar $picard NormalizeFasta I=$op.tmp.fa O=$op.fa`;
`rm -rf $op.tmp.fa`;
`$samtools faidx $op.fa`;
close NP;

my %pos;
open POS, "$op.pos" or die $!;
while (<POS>)
{
    chomp;
    my ($origin, $os, $oe, $new, $ns, $ne) = split /\t/, $_;
    $pos{$origin}{$os}{$oe} = "$new=$ns=$ne";
}
close POS;

for my $chr (keys %gtf)
{
    for my $record (@{$gtf{$chr}})
    {
        my ($source, $feature, $start, $end, $score, $strand, $frame, $attri) = split /\t/, $record;
        for my $s (sort {$a <=> $b} keys %{$pos{$chr}})
        {
            if ($start >= $s)
            {
                for my $e (sort {$a <=> $b} keys %{$pos{$chr}{$s}})
                {
                    if ($end <= $e)
                    {
                        my ($newchr, $news, $newe) = $pos{$chr}{$s}{$e} =~ /^([^=]+)=([^=]+)=([^=]+)$/;
                        $start = $start - $s + $news;
                        $end = $newe - ($e - $end);
                        print NG join("\t", $newchr, $source, $feature, $start, $end, $score, $strand, $frame, $attri);
                    }
                }
            }
        }
    }
}
close NG;

## functions

sub chrsplit
{
    my ($cn, $sp, $seq4sp, $length, $gtf) = @_;
    for my $id (sort keys %{$seq4sp})
    {
        my $part = int($$length{$id} / $sp + 1);
### attent to use Ns split mode...
        my $seq_tmp = $$seq4sp{$id};
        $seq_tmp =~ s/\s+//g;
        my %Ns;
        my $Nfailed = "no";
        findNs($seq_tmp, $cn, \%Ns);
        my $part_len = int($$length{$id} / $part + 1);
        my @part;
        my $inter = $sp - $part_len;
        for my $i (1 .. ($part - 1))
        {
            my $split = $part_len * $i;
            my $part_s = $split - $inter;
            my $part_e = $split + $inter;
            my $ok = "no";
            for my $Ns (keys %Ns)
            {
                my ($Ns_s, $Ns_e) = $Ns =~ /^(\d+)-(\d+)$/;
                if ($Ns_s > $part_s and $Ns_e < $part_e)
                {
                    push @part, int(($Ns_e + $Ns_s)/2);
                    $ok = "yes";
                    last;
                }
            }
            if ($ok eq "no")
            {
                $Nfailed = "yes";
                last;
            }
        }
        if ($Nfailed eq "yes")
        {
### the Ns split is failed, attent to use intergenic split mode...
            @part = ();
            my %Ig;
            my $Ifailed = "no";
            findIg(\@{$$gtf{$id}}, 10000, \%Ig, $$length{$id});
            for my $i (1 .. ($part - 1))
            {
                my $split = $part_len * $i;
                my $part_s = $split - $inter;
                my $part_e = $split + $inter;
                my $ok = "no";
                for my $Ig (keys %Ig)
                {
                    my ($Ig_s, $Ig_e) = $Ig =~ /^(\d+)-(\d+)$/;
                    if ($Ig_s > $part_s and $Ig_e < $part_e)
                    {
                        push @part, int(($Ig_e + $Ig_s)/2);  ## get split site.
                        $ok = "yes";
                        last;
                    }
                }
                if ($ok eq "no")
                {
                    $Ifailed = "yes";
                    last;
                }
            }
            if ($Ifailed eq "yes")
            {
                print STDERR "$id, split failed!\n";
            }
            else
            {
                for my $split_site (@part)
                {
                    substr($seq_tmp, $split_site - 1, 1, "#");
                }
                my @seq_part = split /#/, $seq_tmp;
                my $end = pop @seq_part;
                my $end_begin = pop @part;
                $end_begin ++;
                unshift @part, 0;
                for my $i (0 .. $#seq_part)
                {
                    my $seq_part = $seq_part[$i];
                    $seq_part .= "N";
                    my $seq_begin = $part[$i] + 1;
                    print NF ">$id-$i\n$seq_part\n";
                    my $seq_part_len = length($seq_part);
                    my $seq_end = $seq_begin + $seq_part_len - 1;
                    print NP "$id\t$seq_begin\t$seq_end\t$id-$i\t1\t$seq_part_len\n";
                }
                print NF ">$id-e\n$end\n";
                my $end_len = length($end);
                my $end_end = $end_begin + $end_len - 1;
                print NP "$id\t$end_begin\t$end_end\t$id-e\t1\t$end_len\n";
            }
        }
        else
        {
            for my $split_site (@part)
            {
                substr($seq_tmp, $split_site - 1, 1, "#");
            }
            my @seq_part = split /#/, $seq_tmp;
            my $end = pop @seq_part;
            my $end_begin = pop @part;
            $end_begin ++;
            unshift @part, 0;
            for my $i (0 .. $#seq_part)
            {
                my $seq_part = $seq_part[$i];
                $seq_part .= "N";
                my $seq_begin = $part[$i] + 1;
                print NF ">$id-$i\n$seq_part\n";
                my $seq_part_len = length($seq_part);
                my $seq_end = $seq_begin + $seq_part_len - 1;
                print NP "$id\t$seq_begin\t$seq_end\t$id-$i\t1\t$seq_part_len\n";
            }
            print NF ">$id-e\n$end\n";
            my $end_len = length($end);
            my $end_end = $end_begin + $end_len - 1;
            print NP "$id\t$end_begin\t$end_end\t$id-e\t1\t$end_len\n";
        }
    }
}

sub chrcombine
{
    my ($cn, $max, $seq4cb, $length) = @_;
    my $Ns = 'N'x$cn;
    my ($pos, $num, $seq) = (1, 1, '');
    for my $id (sort keys %{$seq4cb})
    {
        if ($pos > $max)
        {
            print NF ">pseudo_$num\n$seq\n";
            $num ++;
            ($pos, $seq) = (1, '');
        }
        my $end = $pos + $$length{$id} - 1;
        print NP "$id\t1\t$$length{$id}\tpseudo_$num\t$pos\t$end\n";
        my $seq_tmp = $$seq4cb{$id};
        $seq_tmp =~ s/\s+//g;
        $seq .= $seq_tmp.$Ns;
        $pos += $$length{$id} + $cn;
    }
    print NF ">pseudo_$num\n$seq\n";
}

sub findNs
{
    my ($seq, $cn, $Ns) = @_;
    my ($start, $end) = (0)x2;
    while ($seq =~ /(N+)/ig)
    {
        my $Nseq = $1;
        $end = pos($seq);
        my $len = length($Nseq);
        $start = $end - $len + 1;
        $$Ns{"$start-$end"} = $len if ($len > $cn);
    }
}

sub findIg
{
    my ($gtf, $distence, $Ig, $length) = @_;
    my (%start, %end);
    my $twise = $distence * 2;
    my $seq = "0"x$length;
    for my $line (@{$gtf})
    {
        my ($source, $feature, $start, $end, $score, $strand, $frame, $attri) = split /\t/, $line;
        my ($gene_id) = $attri =~ /gene_id "([^;]+)";/;
        if (!exists $start{$gene_id})
        {
            $start{$gene_id} = $start;
            $end{$gene_id} = $end;
        }
        else
        {
            $start{$gene_id} = $start if ($start < $start{$gene_id});
            $end{$gene_id} = $end if ($end < $end{$gene_id});
        }
    }
    for my $gene_id (keys %start)
    {
        my $gene_len = $start{$gene_id} - $end{$gene_id} + 1;
        my $exist = "1"x$gene_len;
        substr($seq, $start{$gene_id} - 1, $gene_len, $exist);
    }
    while ($seq =~ /(0+)g/)
    {
        my $zero = $1;
        my $len = length($zero);
        next if ($len < $twise);
        my $end = pos($zero);
        my $start = $end - $len + 1;
        $end -= $distence;
        $start += $distence;
        $len -= $twise;
        $$Ig{"$start-$end"} = $len;
    }
}


