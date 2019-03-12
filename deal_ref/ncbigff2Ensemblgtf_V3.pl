#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <ncbi.gff|gz> <change_chromesome_name[0|1]>\noutputfiles: .gtf .desc chr.list .attri\n" if (@ARGV != 2);


if ($ARGV[0] =~ /\.gz$/)
{
	open GFF , "gzip -dc $ARGV[0] |" or die $!;
}
else
{
	open GFF, "$ARGV[0]" or die $!;
}

my (%cds, %exon, %rna, %biotype, %gename, %annot, %trans, %chr, %gene, %protein, %geneannot);

while (<GFF>) {
	unless (/^#/){
		chomp;
		my @tmp = split /\t/, $_;
		die "please check the ncbi gff file, the start greater than end in line $.\n" if  ($tmp[3] > $tmp[4]);
		if ($tmp[2] =~ /exon/i) {
			my $info = pop(@tmp);
			my $text = join("\t", @tmp);
			$info =~ s/;/ ;/g;
			$info =~ s/,/ ,/g;
			my ($trans_id) = $info =~ /Genbank:(\S+)\.\d+?\s/;
			my ($gene_id) = $info =~ /GeneID:(\d+)\s/;
			my ($rna) = $info =~ /Parent=(\S+)\s/;
			$trans{$rna} = $trans_id if ($rna && $trans_id && !exists $trans{$rna});
			my ($key) = $info =~ /gbkey=(\S+)\s/;
			$key = "protein_coding" if ($key =~ /mRNA/i);
			my ($annot) = $info =~ /product=([^;]+)/;
			$annot = &hex2chr($annot) if ($annot && $annot =~ /%\w{2}/);
			$annot{$rna} = $annot if ($annot && $annot ne "");
			($key) = $info =~ /ncrna_class=(\S+)\s/ if ($key =~ /ncRNA/i && $info =~ /ncrna_class/);
			$key = "antisense" if ($key =~ /antisense/i);
			if ($rna) {
				$biotype{$rna} = $key if (!exists $biotype{$rna});
			}
			my ($gename) = $info =~ /gene=(\S+)\s/;
			if (defined $rna && defined $trans_id && defined $gene_id) {
				$rna{$rna} = "transcript_accession_id \"$trans_id\"; gene_entrez_id \"$gene_id\";";
				if ($gename){
					$gename{$rna} = $gename;
				}else{
					$gename{$rna} = "-";
				}
				push @{$exon{$rna}}, $text;
			}
		}elsif ($tmp[2] =~ /cds/i) {
			my $info = pop(@tmp);
			my $text = join("\t", @tmp);
#			$info =~ s/;/ ;/g;
			my ($gene_id) = $info =~ /GeneID:(\d+)/;
			$gene_id = "-" unless ($gene_id);
			my ($rna) = $info =~ /Parent=([^;]+)/;
			($rna) = $info =~ /ID=([^;]+)/ unless ($rna);
#			push @{$cds{$rna}}, $text if (defined $rna);
			my ($annot) = $info =~ /product=([^;]+)/;
			my ($protein_id) = $info =~ /protein_id=([^; ]+)/;
			$protein{$rna} = $protein_id;
			$annot = &hex2chr($annot) if ($annot && $annot =~ /%\w{2}/);
			$annot{$rna} = $annot if ($annot && $annot ne "");
			$biotype{$rna} = "protein_coding";
			my ($gename) = $info =~ /gene=([^;]+)/;
			if (defined $rna && defined $protein_id && defined $gene_id) {
				$rna{$rna} = "transcript_accession_id \"$protein_id\"; gene_entrez_id \"$gene_id\";" if !exists $rna{$rna};
				if ($gename){
					$gename{$rna} = $gename;
				}else{
					$gename{$rna} = "-";
				}
				push @{$cds{$rna}}, $text;
			}
		}elsif ($tmp[2] =~ /region/i) {
			my @tmp = split /\t/, $_;
			$tmp[8] =~ s/;/ ;/g;
			my $chr = $tmp[0];
#			my ($name) = $tmp[8] =~ /Name=(\S+)\s/ if ($_ =~ /^\wC/);
			my $name;
			if ($_ =~ /^[A-Z]{1}C_/) {
				($name) = $tmp[8] =~ /Name=(\S+)\s/;
			}else{
				$name = $tmp[0];
			}
			$chr{$chr} = $name if (!exists $chr{$chr} && $name);
		}elsif ($tmp[2] =~ /RNA/i or $tmp[2] =~ /transcript/i) {
			my $info = pop(@tmp);
			my ($rna) = $info =~ /ID=([^;]+);/;
			my ($gene) = $info =~ /Parent=([^;]+);/;
			$gene{$rna} = $gene;
		}elsif ($tmp[2] =~ /gene/i) {
			my $info = pop(@tmp);
			my ($geneid) = $info =~ /ID=([^;]+)/;
			my ($annot) = $info =~ /description=([^;]+)/;
			$annot = "-" unless ($annot);
			$annot = &hex2chr($annot) if ($annot && $annot =~ /%\w{2}/);
			$geneannot{$geneid} = $annot;
		}
	}
}
close GFF;

my $out = $ARGV[0];
$out =~ s/\.gff$//;
my $annout = $out;
my $attri = $out;
$out .= ".gtf";
$annout .= ".desc";
$attri .= ".attri";
open OUT, "> $out" or die $!;
open ANNOT, "> $annout" or die $!;
print ANNOT "trans_id\tgene_id\ttrans_Description\tgene_desc\n";
open ATTRI, "> $attri" or die $!;
print ATTRI "#transcript_id\tgene_id\ttranscript_accession_id\tgene_entrez_id\tprotein_accession_id\tgene_name\ttranscript_biotype\n";

foreach my $r (sort keys %rna)
{
	my $gene = $r;
	$gene = $gene{$r} if (exists $gene{$r});
	print ANNOT "$r\t$gene\t$annot{$r}\t$geneannot{$gene}\n" if (exists $annot{$r});
	my $gn = " ";
	if (!exists $gename{$r}){
		$gename{$r} = " ";
	}else{
		$gn = "gene_name \"$gename{$r}\";";
	}
	my $pacc = " ";
	if (!exists $protein{$r}){
		$protein{$r} = " ";
	}else{
		$pacc = "protein_accession_id \"$protein{$r}\";";
	}
	my ($trans_acc) = $rna{$r} =~ /transcript_accession_id "([^;]+)";/;
	my ($entrez) = $rna{$r} =~ /gene_entrez_id "([^;]+)";/;
	print ATTRI "$r\t$gene\t$trans_acc\t$entrez\t$protein{$r}\t$gename{$r}\t$biotype{$r}\n";
	foreach my $i (@{$exon{$r}})
	{
		my @text = split /\t/, $i;
		$text[0] = $chr{$text[0]} if (exists $chr{$text[0]} && $ARGV[1] == 1);
		my $text = join ("\t", @text);
		print OUT "$text\ttranscript_id \"$r\"; gene_id \"$gene\"; $rna{$r} $pacc $gn transcript_biotype \"$biotype{$r}\";\n";
	}
	foreach my $i (@{$cds{$r}})
	{
		my @text = split /\t/, $i;
		$text[0] = $chr{$text[0]} if (exists $chr{$text[0]} && $ARGV[1] == 1);
		my $text = join ("\t", @text);
		print OUT "$text\ttranscript_id \"$r\"; gene_id \"$gene\"; $rna{$r} $pacc $gn transcript_biotype \"$biotype{$r}\";\n";
	}
	if (scalar @{$exon{$r}} == 0)
	{
		foreach my $i (@{$cds{$r}}){
		my @text = split /\t/, $i;
		$text[0] = $chr{$text[0]} if (exists $chr{$text[0]} && $ARGV[1] == 1);
		$text[2] = "exon";
		my $text = join ("\t", @text);
		print OUT "$text\ttranscript_id \"$r\"; gene_id \"$gene\"; $rna{$r} $pacc $gn transcript_biotype \"$biotype{$r}\";\n";
	}
	}
}

close OUT;

open CHR, "> chr.list" or die $!;
foreach my $c (sort keys %chr) {
	print CHR "$c\t$chr{$c}\n";
}
close CHR;

sub hex2chr
{
	$_[0] =~ s/%(\w{2})/pack("C",hex($1))/eg;
	return $_[0];
}

