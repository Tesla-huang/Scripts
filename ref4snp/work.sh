#!/bin/sh
FA=/Bio/Database/Species/Plant/Triticum_aestivum/Ensembl/release30/RNAseq_Reference/tae.fa
GTF=/Bio/Database/Species/Plant/Triticum_aestivum/Ensembl/release30/RNAseq_Reference/tae.gtf
BIN=/Bio/User/linyifan/script/ref4snp
perl $BIN/rebuild_genome.pl -fa $FA -gtf $GTF -op ./new -not tae.chr.list
yhrun perl ~/pipe/RNA/Preprocess/deal_ref_fasta-gtf-snp.pl new.fa new.gtf new
echo "too naive" > new.4.bt2
echo "too naive" > new.3.bt2
echo "too naive" > new.2.bt2
echo "too naive" > new.1.bt2
echo "too naive" > new.rev.2.bt2
echo "too naive" > new.rev.1.bt2
