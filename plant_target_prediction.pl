#!/usr/bin/perl
use warnings;
use strict;
use FindBin qw($Bin $Script);
use lib $Bin;

use plantTar qw(:ALL);
use Getopt::Long;
use File::Basename;
use File::Path;

my $_cod_file=''; my $_mature_file=''; my $_out=''; my $_name=''; my $_mis=''; my $_slim_flag=0; my $help=0;
GetOptions ("d=s" => \$_cod_file, "m=s"=>\$_mature_file, "o=s"=>\$_out, "n:s"=>\$_name,"s:s"=>\$_mis, "c"=>\$_slim_flag,"h"=>\$help);
my $patmatch_bin = "/Bio/Software/miRNA_Target/patmatch_1.2";

my $cod_file=$_cod_file;
my $mature_file=$_mature_file;
my $mismatches=$_mis? $_mis : 4;

my $out=$_out;

if($help) { &usage; }

unless(-e $cod_file && -e $mature_file ) {
	print "$cod_file not exist" unless -e $cod_file;
	print "$mature_file not exist" unless -e $mature_file;
	&usage;
}

mkpath($out,{verbose => 0, mode => 0755}) unless -e $out;

$_out=~s/\/$//;

open O1, ">$out/$_name\_target.aln" || die $!;
open O2, ">$out/$_name\_target.table" || die $!;
open O3, ">$out/$_name\_target.seq" || die $!;
open O4, ">$out/$_name\_target.patmatched" || die $!;
open PATALN, ">$out/$_name\_target.pat.aln" || die $!;
open L, ">$out/$_name\_target.log" || die $!;

print L "loading dataset...\n";
my $codId_seq={};
my $cod_entry_n=readfasta($cod_file,$codId_seq);
my $matureId_seq={};
my $mature_entry_n=readfasta($mature_file, $matureId_seq);

print L "finish loading dataset\n";
print L "target predicting...\n";
my %mirid2targetid;

#cut a certain length to duplexfold
my $left_offset=30;
my $right_offset=30;
my $progress_record=0;
foreach my $matureId(sort keys %$matureId_seq) {
	$progress_record++;
	my $mir_seq = $matureId_seq->{$matureId}->{seq};
	$mir_seq =~ tr/U/T/;
	my $mir_rev_com = revcom($mir_seq);
	my $pat_match_res = `perl $patmatch_bin/patmatch.pl -n $mir_rev_com $cod_file $mismatches s`;

	print L "\t\t$progress_record $matureId miRNA finished\n";
	next if($pat_match_res !~ /\S+/);

########### patmatch.pl result like this
   # >AK063122:[499,520]
   # AATGCCTCTAGAAAGATCCGAA
###########

	my @split_patmatch=split("\n",$pat_match_res);
	my @pat_mat_title=();
	my @pat_mat_region=(); 
	#make sure you remember there is one space at the end of each line produced by patmatch  

	foreach (@split_patmatch) {
		if(/^>(\S+)/) {
			push @pat_mat_title, $1;
		} elsif(/([ACGTNUKSYMWRBDHV]+)/i) {  ### notice there are Ns existing in the transcripts
			push @pat_mat_region, $1;
		}
	}

#############################################################
# A : adenosine   |   C : cytidine   |   G : guanine   |   T : thymidine   |   U : uridine
# N : A/G/C/T (any)   |   K : G/T (keto)   |   S : G/C (strong)   |   Y : T/C (pyrimidine)   |   M : A/C (amino)   |   W : A/T (weak)   |   R : G/A (purine)
# B : G/T/C   |   D : G/A/T   |   H : A/C/T   |   V : G/C/A

	my %match_num=();

	foreach my $match (@pat_mat_title) {
		next unless($match=~/^(\S+)\:\[(\d+),(\d+)\]$/);
		my $subj_id=$1;
		$match_num{$subj_id}++;
		my $beg=$2;
		my $end=$3;
		my $subj_seq=$codId_seq->{$subj_id}->{seq};
		my $ta_region=shift @pat_mat_region;

		my $subj_seq_len=length $subj_seq;
		my $mRNA_seq=$subj_seq;
		my $new_beg= ($beg-$left_offset<1 ) ? 1 : $beg - $left_offset;
		my $new_end= ($end+$right_offset > $subj_seq_len) ? $subj_seq_len : $end+$right_offset ;

		my $subseq_for_hybrid=&get_seg($subj_seq, $new_beg, $new_end);

		print L "$subseq_for_hybrid sequence used to duplexfold...\n";

		my $pass = plantTar::pick_target($mir_seq, $ta_region, $subseq_for_hybrid, $matureId, $subj_id, "location[$beg,$end]\t|\t".$codId_seq->{$subj_id}->{desc}, \*O1, \*L, \*PATALN, $mismatches, $mRNA_seq, $beg, $end);

		if($pass){
			push @{$mirid2targetid{$matureId}},"$subj_id\[$codId_seq->{$subj_id}->{desc}\]" unless ($_slim_flag);
			push @{$mirid2targetid{$matureId}},"$subj_id" if($_slim_flag);
			print O3 ">mir:$matureId\t$matureId_seq->{$matureId}->{seq}\tpupative-target:$match\tdescription:$codId_seq->{$subj_id}->{desc}\n";
			print O3 $subj_seq,"\n";
			print O4 ">mir:$matureId\t$matureId_seq->{$matureId}->{seq}\tpupative-target:$match\tdescription:$codId_seq->{$subj_id}->{desc}\n";
			print O4 $subj_seq,"\n";
		} else {
			print O4  ">mir:$matureId not hit the plant target predicton critera!\t$matureId_seq->{$matureId}->{seq}\tpupative-target:$match\n";
			print O4  $subj_seq,"\n";
		}
		print L "$subseq_for_hybrid sequence finish duplexfold!\n";
	}
}

print L "finish target predicting\n";

### target table
foreach my $matureId (sort keys %mirid2targetid) {
	print O2 $matureId,"\t", scalar @{$mirid2targetid{$matureId}} ,"\t" , join('~~', @{$mirid2targetid{$matureId}}),"\n";
}

close O1 || die $!; close O2 || die $!; close O3 || die $!; close O4 || die $!; close  L || die $!; close PATALN || die $!;

### modified by tianwei in 2009-7-31
open ALN, "$out/$_name\_target.aln" || die $!;
open STAT, ">$out/$_name\_target.stat" || die $!;
my %stat;
while (<ALN>) {
	if (/>(\S+)/) {
		$stat{$1}++;
	}
}
close ALN;

my $mir_n; my $tgt_n; map {$mir_n++;$tgt_n+=$stat{$_};} keys %stat;
print STAT "Sample_name\tmiRNA_number\ttarget_number\n";
my $smp_nm=$_name; $smp_nm=~s/\/$//;
unless($mir_n){$mir_n=0;$tgt_n=0;}
print STAT "$smp_nm\t$mir_n\t$tgt_n";
close STAT;

#####################################

open README,">$out/README" or die $!;
print README "plant targets prediction pipeline introduction

this pipeline will input the reads in a FASTA format file containing sRNA sequences and the user-provided transcript database then will look for targets of that sequence in the user-provided transcript database based on the following rules\.
Rules used\:

The rules used for target prediction are based on those suggested by Allen et al. (microRNA-directed phasing during trans-acting siRNA biogenesis in plants\. Cell, 2005, 121:207-221) - Supplemental document S1 and by Schwab et al\. (Specific effects of microRNAs on the plant transcriptome\. Dev\. Cell\, 2005\, 8\: 517 - 527)\.

Specifically miRNA/target duplexes must obey the following rules\:

    \* No more than four mismatches between sRNA \& target (G-U bases count as 0\.5 mismatches)
    \* No more than two adjacent mismatches in the miRNA/target duplex
    \* No adjacent mismatches in in positions 2\-12 of the miRNA\/target duplex (5\' of miRNA)
    \* No mismatches in positions 10-11 of miRNA/target duplex
    \* No more than 2\.5 mismatches in positions 1\-12 of the of the miRNA/target duplex (5\' of miRNA)
    \* Minimum free energy (MFE) of the miRNA\/target duplex should be \>\= 74% of the MFE of the miRNA bound to it\'s perfect complement 

Results\:

An example entry from a target prediction results file is shown below\:

Key\:

   1\. sRNA ID | targets accession | Any information/annotation this sequence may have
   2\. target site description
   3\. Alignment of the miRNA (bottom sequence) to the target site (top sequence)\:
          \* \"|\" represents a base pair
          \* \"x\" represents a mismatch
          \* \"o\" represents a G-U basepair
          \* energy information and miRNA/target duplex energy raito to perfect complement of miRNA/target duplex energy 

>mature id here | coding id here | descriptions here
#Region 1 to 21 of mature id here basepairs with65 to 86 of coding id here relative to the 5' of the given strand
                     5'UCCCGGAGAGCUCAAGUGUGA3'
                       x||||||||||o||x||||||
3'UAGACGAGUUUGGCAGGACCAUGGGCCUCUCGGGUCCACACUUCGUAGUUAUCAUGUGAGUGUGAACUCCAG5' ( -36.60[85.92%] )
";

close README;

################ sub routine

sub get_seg{
	my $str=shift;
	my $start=shift;
	my $end=shift;
	my $len=$end-$start+1;
	return substr($str,$start-1,$len); #substr 0-index, criterira is 1-index
}


sub readfasta {
	my $infile=shift; my $seqId_seq=shift;
	my $c=0;
	open IN, $infile || die $!;
	my $seqId;
	while (<IN>) {
		if (/^>(\S+)(.*)/) {
			$seqId = $1;
			my $desc = $2; $desc =~ s/^\s+//; $desc =~ s/\s+$//;
			$c++;
			$seqId_seq->{$seqId}->{'desc'} = $desc;
		} else {
			$_=~ s/\s//g;
			$seqId_seq->{$seqId}->{seq} .= $_;
		}
	}
	close IN;
	return $c;
}

sub rev{
    my($sequence)=@_;
    my $rev=reverse $sequence;
    return $rev;
}

sub com{
    my($sequence)=@_;
    $sequence=~tr/acgtuACGTU/TGCAATGCAA/;
    return $sequence;
}

sub revcom{
    my($sequence)=@_;
    my $revcom=rev(com($sequence));
    return $revcom;
}

sub usage {
	print <<USAGE;
Program: pick plant miR targets
Contact: microRNA group[mireap series]
<liqb\@genomics.org.cn>
<tianwei\@genomics.org.cn>
<jiangpeiyong\@genomics.org.cn>

<xmiao\@genedenovo.com> modified by miaoxin 15-11-07

Usage: pick_plant_targert.pl -m <mir.fa> -d <target.fa> -o <result dir>
  Options:
  -m <file>    miRNA mined frome Small RNA library, fasta format, forced
  -d <file>    target sequences ( exon.fa / cds.fa ), fasta format, forced
  -o <file>    dir, file where results produce, forced
  -n <string>  prefix for the output name, forced
  -s [num]     mismatches number, optional default=4
  -c           flag for table without descriptions but just with target ID
  -h           Help

USAGE
	exit;
}
