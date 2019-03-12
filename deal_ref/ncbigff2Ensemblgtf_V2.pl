#!/usr/bin/perl -w

use strict;

die "Usage: perl $0 <ncbi.gff>\nncbi.gtf\n" if (@ARGV != 1);

my (%cds, %exon, %rna, %biotype, %gename, %annot, %trans, %chr);
open GFF, "$ARGV[0]" or die $!;
while (<GFF>) {
	unless (/^#/){
		my @tmp = split /\t/, $_;
		die "please check the ncbi gff file, the start greater than end in line $.\n" if  ($tmp[3] > $tmp[4]);
		if ($tmp[2] =~ /exon/i) {
			my $info = pop(@tmp);
			my $text = join("\t", @tmp);
			$info =~ s/;/ ;/g;
			$info =~ s/,/ ,/g;
			my ($trans_id) = $info =~ /Genbank:(\S+)\.\d+?\s/;
			my ($gene_id) = $info =~ /GeneID:(\S+)\s/;
			my ($rna) = $info =~ /Parent=(\S+)\s/;
			$trans{$rna} = $trans_id if ($rna && $trans_id && !exists $trans{$rna});
			my ($key) = $info =~ /gbkey=(\S+)\s/;
			$key = "protein_coding" if ($key =~ /mRNA/i);
			my ($annot) = $info =~ /product=(.*?) ;/;
			$annot = &hex2chr($annot) if ($annot && $annot =~ /%\w{2}/);
			$annot{$rna} = $annot if (!exists $annot{$rna});
			($key) = $info =~ /ncrna_class=(\S+)\s/ if ($key =~ /ncRNA/i);
			if ($rna) {
				$biotype{$rna} = $key if (!exists $biotype{$rna});
			}
			my ($gename) = $info =~ /gene=(\S+)\s/;
			if (defined $rna && defined $trans_id && defined $gene_id) {
				$rna{$rna} = "transcript_id \"$trans_id\"; gene_id \"ncbi-$gene_id\";";
				$gename{$rna} = $gename if ($gename);
				push @{$exon{$rna}}, $text;
			}
		}elsif ($tmp[2] =~ /cds/i) {
			my $info = pop(@tmp);
			my $text = join("\t", @tmp);
			$info =~ s/;/ ;/g;
			my ($rna) = $info =~ /Parent=(\S+)\s/;
			push @{$cds{$rna}}, $text if (defined $rna);
			my ($annot) = $info =~ /product=(.*?) ;/;
			$annot = &hex2chr($annot) if ($annot && $annot =~ /%\w{2}/);
			$annot{$rna} = $annot if (!exists $annot{$rna});
		}elsif ($tmp[2] =~ /region/i) {
			my @tmp = split /\t/, $_;
			$tmp[8] =~ s/;/ ;/g;
			my $chr = $tmp[0];
#			my ($name) = $tmp[8] =~ /Name=(\S+)\s/ if ($_ =~ /^\wC/);
			my $name;
			if ($_ =~ /^\wC/) {
				($name) = $tmp[8] =~ /Name=(\S+)\s/;
				$name =~ tr/XY/xy/ if ($name);
			}else{
				$name = $tmp[0];
			}
			$chr{$chr} = $name if (!exists $chr{$chr} && $name);
		}
	}
}
close GFF;

my $out = $ARGV[0];
my $annout = $ARGV[0];
$out =~ s/gff$/gtf/;
$annout =~ s/gff$/desc/;
open OUT, "> $out" or die $!;
open ANNOT, "> $annout" or die $!;
print ANNOT "Transcript_ID\tNr-Annotation";
foreach my $r (sort keys %rna) {
	print ANNOT "\n$trans{$r}\t$annot{$r}" if (exists $annot{$r});
	if (!exists $gename{$r}) {
		$gename{$r} = " ";
	}else{
		$gename{$r} = "gene_name \"$gename{$r}\";";
	}
	foreach my $i (@{$exon{$r}}) {
		my @text = split /\t/, $i;
		$text[0] = $chr{$text[0]} if (exists $chr{$text[0]});
		my $text = join ("\t", @text);
		print OUT "$text\t$rna{$r} $gename{$r} transcript_biotype \"$biotype{$r}\";\n";
	}
	foreach my $i (@{$cds{$r}}) {
		my @text = split /\t/, $i;
		$text[0] = $chr{$text[0]} if (exists $chr{$text[0]});
		my $text = join ("\t", @text);
		print OUT "$text\t$rna{$r} $gename{$r} transcript_biotype \"$biotype{$r}\";\n";
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

