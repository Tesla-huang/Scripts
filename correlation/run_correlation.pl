#!usr/bin/perl -w
use strict;
 use Getopt::Long;

use FindBin qw($Bin $Script);
$Bin="/Bio/User/lanhaofa/program/correlation";

sub usage {
	print STDERR << "USAGE";
=head1 name
	run_correlation.pl
=head1 descripyion
	-exp1	expfile1
	-exp2	expfile2
	-r	row(defalut 2)
	-desc1	descfile1
	-desc2	descfile2
	-p	filt p-value 
	-c	filt cor
	-target target.list
	-relation	negative or postive or all corletaion (N,P and A)
	-m	method(pearson or spearman)
=head1 example
	perl run_correlation.pl -exp1 mirna.exp -exp2 mrna.exp -desc1 mirna.desc -desc2 mrna.desc -target target.list -relation N -m  spearman	
USAGE
}

my ($out,$m,$target,$exp1,$exp2,$p,$c,$row,$desc1,$desc2,$relation);
GetOptions(
	"exp1:s"=>\$exp1,
	"exp2:s"=>\$exp2,
	"r:s"	=>\$row,
	"desc1:s"=>\$desc1,
	"desc2:s"=>\$desc2,
	"p:s" =>\$p,
	"c:s" =>\$c,
	"relation:s"=>\$relation,
	"m:s" =>\$m,
	"o:s" =>\$out,
	"target:s" =>\$target
);

$row ||= 2;
$out ||= "./";
 if (!defined $exp1 && !defined $exp2 && !defined $m)
 {
	&usage();
	exit 1;
}
open OUT,">$out/run.sh" or die $!;
if ($m eq "pearson")
{
	print OUT "Rscript $Bin/file_run_pearson.R $exp1 $exp2 $row\n";
}
elsif ($m eq "spearman")
{
	print OUT "Rscript $Bin/file_run_spearman.R $exp1 $exp2 $row\n";
}
print OUT "fgrep -f $target $exp1.$exp2.xls >$exp1-vs-$exp2.target.$m\n";
print OUT "head -1 $exp1 \|cut -f1 >1.head\n";
print OUT "head -1 $exp2 \|cut -f1 >2.head\n";
print OUT "echo -e cor\"\\t\"pvalue\"\\t\"fdr\"\\t\" >3.head\n";
print OUT "paste 1.head 2.head 3.head >head\n";
print OUT "cat head $exp1-vs-$exp2.target.$m >$exp1-vs-$exp2.target.$m.tmp\n";
print OUT "rm 1.head 2.head 3.head head\n";
print OUT "perl $Bin/add_annot.pl $exp1 $exp1-vs-$exp2.target.$m.tmp 1 > $exp1-vs-$exp2.target.$m.tmp1\n";
print OUT "perl $Bin/add_annot.pl $exp2 $exp1-vs-$exp2.target.$m.tmp1  2 > $exp1-vs-$exp2.target.$m.tmp2\n";

if (defined $desc1  )
{
	print OUT  "perl $Bin/add_annot.pl $desc1 $exp1-vs-$exp2.target.$m.tmp2 1 >$exp1-vs-$exp2.target.$m.tmp3\n";
}
else
{
	print OUT "mv $exp1-vs-$exp2.target.$m.tmp2 $exp1-vs-$exp2.target.$m.tmp3\n";
}
if (defined $desc2)
{
	print OUT  "perl $Bin/add_annot.pl $desc2 $exp1-vs-$exp2.target.$m.tmp3 2 >$exp1-vs-$exp2.target.$m.tmp4\n";
}
else
{
	print OUT "mv $exp1-vs-$exp2.target.$m.tmp3 $exp1-vs-$exp2.target.$m.tmp4\n";
}
print OUT "mv $exp1-vs-$exp2.target.$m.tmp4 $exp1-vs-$exp2.target.$m.xls\n";
print OUT "rm $exp1-vs-$exp2.target.$m.tmp*\n";

print OUT "head -1 $exp1-vs-$exp2.target.$m.xls >head \n";
if (defined $p && defined $c)
{
	if ($relation eq "N")
	{
		print OUT "awk '\$4<$p && \$3<-$c' $exp1-vs-$exp2.target.$m.xls >$exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.negative.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.negative.filt >$exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.negative.filt.xls \n";
		
	}
	elsif ($relation eq "P")
	{
		print OUT  "awk '\$4<$p && \$3<$c' $exp1-vs-$exp2.target.$m.xls  >$exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.positive.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.positive.filt >$exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.positive.filt.xls \n";
	}
	elsif ($relation eq "A" || !defined $relation)
	{
		print OUT "awk '\$4<$p && (\$3<-$c || \$3<$c)'  $exp1-vs-$exp2.target.$m.xls  > $exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.filt >$exp1-vs-$exp2.target.$m.pvaule_$p.cor_$c.filt.xls\n";

	}
}
elsif(defined $p && (!defined $c))
{
	print  OUT "awk '\$4<$p ' $exp1-vs-$exp2.target.$m.xls >$exp1-vs-$exp2.target.$m.pvaule.filt\n";
	print OUT "cat head $exp1-vs-$exp2.target.$m.pvaule.filt>$exp1-vs-$exp2.target.$m.pvaule.filt.xls \n";
}
elsif ( ( !defined $p) && defined $c)
{
	if ($relation eq "N")
        {
                print OUT "awk '\$3<-$c' $exp1-vs-$exp2.target.$m.xls > $exp1-vs-$exp2.target.$m.cor_$c.negative.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target.$m.cor_$c.negative.filt >$exp1-vs-$exp2.target.$m.cor_$c.negative.filt.xls\n";	
	}
        elsif ($relation eq "P")
        {
                print  OUT "awk '\$3<$c' $exp1-vs-$exp2.target.$m.xls >$exp1-vs-$exp2.target.$m.cor_$c.positive.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target.$m.cor_$c.positive.filt >$exp1-vs-$exp2.target.$m.cor_$c.positive.filt.xls \n";
	}
	 elsif ($relation eq "A" || !defined $relation)
        {
                print  OUT "awk '\$3<-$c || \$3<$c'  $exp1-vs-$exp2.target.$m.xls >$exp1-vs-$exp2.target$m.cor_$c.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target$m.cor_$c.filt >$exp1-vs-$exp2.target$m.cor_$c.filt.xls\n";
        }
}
elsif ( (!defined $c) && (!defined $p))
{
	if ($relation eq "N")
	{
		 print OUT "awk '\$3<0' $exp1-vs-$exp2.target.$m.xls > $exp1-vs-$exp2.target.$m.negative.filt\n";
		print OUT "cat head $exp1-vs-$exp2.target.$m.negative.filt >$exp1-vs-$exp2.target.$m.negative.filt.xls\n";
	}
	elsif ($relation eq "P")
        {
                print  OUT "awk '\$3>0' $exp1-vs-$exp2.target.$m.xls > $exp1-vs-$exp2.target.$m.positive.filt\n";
		print OUT "cat head  $exp1-vs-$exp2.target.$m.positive.filt >$exp1-vs-$exp2.target.$m.positive.filt.xls\n";
	}
}
print OUT "rm *filt\n";
