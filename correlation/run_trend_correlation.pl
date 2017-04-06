#!usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;
use FindBin qw($Bin $Script);
$Bin="/home/linyifan/script/correlation";

sub usage {
        print STDERR << "USAGE";
=head1 name
        run_correlation.pl
=head1 descripyion
	-mrna	mrna_rpkm_file (full path)
	-mirna	mirna_tmp_file (full path)
	-outdir output dir (default "./")
	-annot	mrna_go_annot_file
	-desc	mrna_desc_file
	-n	sample number
	-ko	ko file
	-s	species (animal,plant,fungi,microorganism,prokaryote)
	-p 	filt p-value (default none)
	-c	filt cor (default 0.5)
	-target target gene file (full path)
=head1 example
        perl run_correlation.pl -mrna mrna.exp  -mirna mirna.exp -annot mrna.go.annot -desc desc.xls -ko special.ko -target target.list  -c 0.5 -outdir ./
USAGE
}

my ($outdir,$mrna,$mirna,$target,$annot,$pvalue,$cor,$relation,$method,$ko,$desc,$s,$num);
GetOptions(
	"mrna:s"=>\$mrna,
	"mirna:s"=>\$mirna,
	"target:s"=>\$target,
	"annot:s"=>\$annot,
	"p:s"=>\$pvalue,
	"c:s"=>\$cor,
	"relation:s"=>\$relation,
	"m:s"=>\$method,
	"desc:s"=>\$desc,
	"ko:s"=>\$ko,
	"s:s"=>\$s,
	"outdir:s"=>\$outdir,
	"n:s"=>\$num
);

$outdir ||= "./";
$cor ||= "0.5";
my $trend="/home/linyifan/bin/Trend/Trend_new.pl";

if (!defined $mrna && !defined $mirna && !defined $ko && !defined $desc && !defined $annot && !defined $s && !defined $target)
{
	&usage();
	exit 1;
}

my $num1=$num+1;

open OUT,">$outdir/main.sh" or die $!;
`mkdir -p $outdir/mRNA`;
`perl $trend -i $mrna -o $outdir/mRNA -ko $ko -annot $annot -komap /Bio/Database/Database/kegg/data/map_class/$s\_ko_map.tab -desc $desc`;
`mkdir -p $outdir/miRNA`;
`perl $trend -i $mirna -o $outdir/miRNA`;

print OUT "mkdir -p $outdir/correlation\n";
print OUT "cd $outdir/correlation\n";
my @mirna_file=`ls $outdir/miRNA/Trend_analysis/profil*xls`;
my @mrna_file=`ls $outdir/mRNA/Trend_analysis/profil*xls`;	
foreach my $mirna_p ( @mirna_file)
{
	chomp $mirna_p;
	my $id1;
	if ($mirna_p=~/profile(\d+)\.xls/)
	{
		$id1=$1;
	}
	my $mirna_n =basename $mirna_p;
	print OUT "cut -f 1-$num1 $mirna_p >$outdir/correlation/mirna.$mirna_n\n";
        foreach my $mrna_p(@mrna_file)
        {
                chomp $mrna_p;
		my $mrna_n=basename $mrna_p;
		my $id2;
		if ($mrna_p=~/profile(\d+)\.xls/)
		{
			$id2=$1;
		}			
		print OUT "fishInWinter.pl -bf table -ff table $mrna_p $mrna |cut -f 1-$num1> $outdir/correlation/mrna.$mrna_n\n";
		
		print  OUT "Rscript $Bin/file_run_spearman.R mirna.$mirna_n mrna.$mrna_n 2 \n";
		print OUT "perl $Bin/get_target.pl $target mirna.$mirna_n.mrna.$mrna_n.xls|cut -f 1-3 |awk '{print \$0\"\\t\"\$1\"\\t$id1\"}'  >mirna.$mirna_n-vs-mrna.$mrna_n.target\n";
		print OUT "perl $Bin/add_annot.pl $mirna_p mirna.$mirna_n-vs-mrna.$mrna_n.target 1 |awk '{print \$0\"\\t\"\$2\"\\t$id2\"}'>mirna.$mirna_n-vs-mrna.$mrna_n.target2\n";
		print OUT "perl $Bin/add_annot.pl $mrna_p mirna.$mirna_n-vs-mrna.$mrna_n.target2 2 > mirna.$mirna_n-vs-mrna.$mrna_n.target.xls\n";
		print OUT "rm mirna.$mirna_n-vs-mrna.$mrna_n.target mirna.$mirna_n-vs-mrna.$mrna_n.target2\n";
	}
}
print OUT "cat *target.xls >rho_miRNA_RNA.xls\n";
print OUT "awk '\$3<-$cor' rho_miRNA_RNA.xls >rho_miRNA_RNA.filt.xls\n";
print OUT "echo -e \"ID\\tGeneID\\trho\\tID\\tProfile\" >head1\n";
print OUT "head -1 $outdir/miRNA/Trend_analysis/all.xls |cut -f 2- >head2\n";
print OUT "paste head1 head2 >head3\n";
print OUT "echo -e \"GeneID\\tProfile\" >head4\n";
print OUT "paste head3 head4 >head5\n";
print OUT "head -1 $outdir/mRNA/Trend_analysis/all.xls |cut -f 2- >head6\n";
print OUT "paste head5 head6 >head\n";
print OUT "cat head rho_miRNA_RNA.filt.xls >rho_miRNA_RNA_annot.xls\n";
print OUT "rm head*\n";

print OUT "mkdir -p $outdir/upload\n";
print OUT "cp -r $outdir/mRNA/Trend_analysis $outdir/upload/RNA_Trend_analysis\n";
print OUT "cp -r $outdir/miRNA/Trend_analysis $outdir/upload/miRNA_Trend_analysis\n";
print OUT "cp $outdir/correlation/rho_miRNA_RNA_annot.xls $outdir/upload \n";
print OUT "cp $Bin/readme.docx $outdir/upload \n";	
`sh $outdir/main.sh`;			
