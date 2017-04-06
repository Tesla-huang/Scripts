Rscript /Bio/User/lanhaofa/program/correlation/file_run_spearman.R miRNA.exp mRNA.exp 2
fgrep -f target.list miRNA.exp.mRNA.exp.xls >miRNA.exp-vs-mRNA.exp.target.spearman
head -1 miRNA.exp |cut -f1 >1.head
head -1 mRNA.exp |cut -f1 >2.head
echo -e cor"\t"pvalue"\t"fdr"\t" >3.head
paste 1.head 2.head 3.head >head
cat head miRNA.exp-vs-mRNA.exp.target.spearman >miRNA.exp-vs-mRNA.exp.target.spearman.tmp
rm 1.head 2.head 3.head head
perl /Bio/User/lanhaofa/program/correlation/add_annot.pl miRNA.exp miRNA.exp-vs-mRNA.exp.target.spearman.tmp 1 > miRNA.exp-vs-mRNA.exp.target.spearman.tmp1
perl /Bio/User/lanhaofa/program/correlation/add_annot.pl mRNA.exp miRNA.exp-vs-mRNA.exp.target.spearman.tmp1  2 > miRNA.exp-vs-mRNA.exp.target.spearman.tmp2
mv miRNA.exp-vs-mRNA.exp.target.spearman.tmp2 miRNA.exp-vs-mRNA.exp.target.spearman.tmp3
perl /Bio/User/lanhaofa/program/correlation/add_annot.pl zma.desc.xls miRNA.exp-vs-mRNA.exp.target.spearman.tmp3 2 >miRNA.exp-vs-mRNA.exp.target.spearman.tmp4
mv miRNA.exp-vs-mRNA.exp.target.spearman.tmp4 miRNA.exp-vs-mRNA.exp.target.spearman.xls
rm miRNA.exp-vs-mRNA.exp.target.spearman.tmp*
head -1 miRNA.exp-vs-mRNA.exp.target.spearman.xls >head 
awk '$3<0' miRNA.exp-vs-mRNA.exp.target.spearman.xls > miRNA.exp-vs-mRNA.exp.target.spearman.negative.filt
cat head miRNA.exp-vs-mRNA.exp.target.spearman.negative.filt >miRNA.exp-vs-mRNA.exp.target.spearman.negative.filt.xls
rm *filt
