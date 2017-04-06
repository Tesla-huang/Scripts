#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename qw(dirname basename);

die "perl $0 <file: norm.fpkm/diff.fpkm/filterstat> <option: withingroup/betweengroup/de-q-0.05/filter/fpkm> <outprefix>
Note: de-q-0.05 de-q-0.01 de-p-0.05 de-p-0.01 etc." if(@ARGV ne 3);

open EXP, $ARGV[0] or die $!;
my $string = <EXP>;
chomp($string);
my @labels = split /\t/, $string;
shift @labels;
=cut
if($ARGV[1] =~ /inter|fpkm/)
{
	@labels = map {$_ =~ s/_\d+$// ? $_ : $_} @labels;
}
=cut
my $ttt = "withingroup";
if($ARGV[1] eq "betweengroup")
{
	$ttt = $ARGV[1];
	$ARGV[1] = "withingroup";
}
my ($sum, @gene, %hash, @rc, @final);

if($ARGV[1] eq "betweengroup")
{
	open OUT, ">> $ARGV[2].stat" or die $!;
	my ($x, $flag) = (0, 0);
	for(my $i = 0; $i < @labels; $i ++)
	{
		if(exists $hash{$labels[$i]})
		{
			push @{$rc[$x]}, $i;
			$flag = 1;
		}else{
			$x ++ if($flag == 1);
			$hash{$labels[$i]} = 0;
			push @final, $labels[$i];
			push @{$rc[$x]}, $i;
		}
	}
=cut
	for (my $i = 0; $i < @rc; $i ++)
	{
		for (my $j = 0; $j < @{$rc[$i]}; $j ++)
		{
			print "$i\t$rc[$i][$j]\n";
		}
	}
=cut
	while(<EXP>)
	{
		chomp;
		my @tmp = split;
		for(my $i = 0; $i < @rc; $i ++)
		{
			my $fpkm;
			$gene[$i]{new} = 0;
			for(my $j = 0; $j < @{$rc[$i]}; $j ++)
			{
				$fpkm += $tmp[$rc[$i][$j] + 1];
			}
			if($fpkm > 0.001 and $tmp[0] !~ /^XLOC_|TCONS_/)
			{
				$gene[$i]{ref} ++;
			}elsif($fpkm > 0){
				$gene[$i]{new} ++;
			}
		}
	}
	print OUT "\nTYPE: betweengroup\n";
	for(my $i = 0; $i < @final; $i ++)
	{
		print OUT "$final[$i]\t";
		foreach my $key(sort keys %{$gene[$i]})
		{
			print OUT "$key: $gene[$i]{$key}\t";
		}
		print OUT "\n";
	}

}elsif($ARGV[1] eq "withingroup"){
	open OUT, "> $ARGV[2].stat" or die $!;
	my ($all_sum, $new_sum, $sum) = (0, 0, 0);
	while(<EXP>)
	{
		chomp;
		my @tmp = split;
		my ($all, $new) = (0, 0);
		for(my $i = 1; $i < @tmp; $i ++)
		{
			$all += $tmp[$i];
			$new += $tmp[$i] if($tmp[0] =~ /^XLOC_|TCONS_/);
			#$gene[$i - 1]{new};
			$gene[$i - 1]{new} = 0 unless(exists $gene[$i - 1]{new}); ## modif by guanpeikun || Mar 23, 2015
			if($tmp[$i] > 0.001 and $tmp[0] !~ /^XLOC_|TCONS_/)
			{
				$gene[$i - 1]{ref} ++;
			}elsif($tmp[$i] > 0.001){
				$gene[$i - 1]{new} ++;
			}
		}
		$all_sum ++ if($all > 0);
		$new_sum ++ if($new > 0);
		$sum ++ if($_ !~ /^XLOC_|TCONS_/);
	}
	print OUT "All genes: $sum\n";
	print OUT "All samples cover: $all_sum\n$new_sum of these are new gene\n\n";
	print OUT "TYPE: $ttt\n";
	for(my $i = 0; $i < @labels; $i ++)
	{
		print OUT "$labels[$i]\t";
		foreach my $key(sort keys %{$gene[$i]})
		{
			print OUT "$key: $gene[$i]{$key}\t";
		}
		print OUT "\n";
	}

}elsif($ARGV[1] =~ /^de/){
	open OUT, ">> $ARGV[2].stat" or die $!;
	print OUT "\tUP\tDOWN\n" if(!-s "$ARGV[2].stat");
	my $outname = basename($ARGV[0]);
	$outname =~ s/\.xls//;
	my ($type, $value) = (split /-/, $ARGV[1])[1..2];
	my (%gene, %glist, $dir, %all);
	$dir = dirname($ARGV[2]);
	open DE, "> $dir/$outname.filter.xls" or die $!;
	print DE "$string\n";
	#$dir = dirname($dir);
	mkdir "$dir/enrichment";
	$outname =~ s/\.isoforms|\.genes//;
	open GLIST, "> $dir/enrichment/$outname.glist" or die $!;
	my $u = 0;
	my $d = 0;
	while(<EXP>)
	{
		chomp;
		my @tmp = split;
		my $bz;
		if($type eq "p")
		{
			$bz = $tmp[6];
		}elsif($type eq "q"){
			$bz = $tmp[7];
		}else{
			die "please choose p or q\n";
		}
#		push @{$all{$tmp[3]."-vs-".$tmp[4]}}, $_;
		if(abs($tmp[5]) > 1 and $bz < $value)
		{
			print DE "$_\n";
#			$hash{$tmp[3]."-vs-".$tmp[4]} ++;
#			if($tmp[0] !~ /^XLOC/)
#			{
#				my $result = "$tmp[0]\t$tmp[9]";
#				push @{$glist{$tmp[3]."-vs-".$tmp[4]}}, $_;
#			}
			if($tmp[5] > 1)
			{
				print GLIST "$tmp[0]\t$tmp[5]\n";
				$u ++;
#				$gene{$tmp[0]}[0] ++;
			}elsif($tmp[5] < -1){
				print GLIST "$tmp[0]\t$tmp[5]\n";
				$d ++;
#				$gene{$tmp[0]}[1] ++;
			}
		}
	}
	print OUT "$outname\t$u\t$d\n";
#	open STAT, ">> $dir/enrichment/enrich.stat" or die $!;
=cut
	foreach my $key(keys %hash)
	{
		$gene{$key}[0] = 0 if(!defined $gene{$key}[0]);
		$gene{$key}[1] = 0 if(!defined $gene{$key}[1]);
		print OUT "$key\t$gene{$key}[0]\t$gene{$key}[1]\n";
		open ALL, "> $dir/upload/expressionStat/$key.DE.xls" or die $!;
		print ALL "$string\n";
		print ALL join "\n", @{$all{$key}};
#		print STAT "$key.glist ";
		open GLIST, "> $dir/enrichment/$key.DEfilter.txt" or die $!;
		print GLIST "$string\n";
		print GLIST join "\n", @{$glist{$key}};
		`cp $dir/enrichment/$key.DEfilter.txt $dir/upload/expressionStat/$key.DEfilter.xls`;
	}
=cut

#	my $group = keys %hash;
#	if($group < 6)
#	{
=cut
		open CMD, "> $ARGV[2].r" or die $!;
		print CMD "
		dat <- read.table(\"$ARGV[2].stat\", header=T)
		id <- attr(dat,\"names\")
		png(\"$ARGV[2].v.png\",width=800,height=600)
		par(mar=c(5,5,4,3))
		co <- c(\"#fb6a4a\", \"#74c476\")
		mat <- t(as.matrix(dat))
		bp <- barplot(mat,beside=T,ylab=\"Number of Genes\",main=\"DiffExp Gene Statistics\",cex.main=2,cex.lab=2,font.lab=2,ylim=c(0,1.2*max(dat)),col=co)
		y_up <- as.vector(rbind(dat\$UP,dat\$DOWN))
		y_axis <- round(y_up + 5)
		text(x=bp, y=y_axis, labels=y_up)
		legend(\"topright\",legend=id,cex=1,col=co,pch=15, bty = \"n\", pt.cex = 2)
		abline(h=axTicks(2),lty=2,col=rgb(0,0,0,0.5))
		dev.off()
		";
		`Rscript $ARGV[2].r`;
		close CMD;
#	}else{
		open CMD, "> $ARGV[2].r" or die $!;
		print CMD "
		dat <- read.table(\"$ARGV[2].stat\", header=T)
		id <- attr(dat,\"names\")
		len <- length(rownames(dat))
		png(\"$ARGV[2].h.png\",width=800,height=len*50)
		par(mar=c(5,15,5,2))
		cr <- c(\"#fb6a4a\", \"#74c476\")
		mat <- t(as.matrix(dat))
		bp <- barplot(mat,beside=T,main=\"DiffExp Gene Statistics\",xlab = \"Number of Genes\", cex.main=2, cex.lab=1.5, col=cr,cex.axis=1.4, cex.names = 1.4, xlim = c(0,1.2*max(dat)), horiz=TRUE, las=1)
		y_up <- as.vector(rbind(dat\$UP,dat\$DOWN))
		y_axis <- round(y_up + 2)
		text(x=y_axis, y=bp, labels=y_up, cex = 1.2)
		legend(\"topright\",legend=id,cex=2,col=cr,pch=15, bty = \"n\", pt.cex = 2)
		abline(v=axTicks(2),lty=2,col=rgb(0,0,0,0.5))
		dev.off()
		";
#	}
		`Rscript $ARGV[2].r`;
		close CMD;
		
	`rm $ARGV[2].r -rf`;
=cut
	
}elsif($ARGV[1] eq "fpkm"){
	open OUT, "> $ARGV[2].fpkm" or die $!;
	print OUT "value\tid\n";
	while(<EXP>)
	{
		chomp;
		my @tmp = split;
		for(my $i = 0; $i < @labels; $i ++)
		{
			next if($tmp[$i + 1] == 0);
			my $v = log($tmp[$i + 1]) / log(10);
			next if($v < -3 or $v > 5);
			print OUT "$v\t$labels[$i]\n";
		}
	}
	open CMD, "> $ARGV[2].r" or die $!;
	print CMD "
		library(ggplot2)
		dat <- read.table(\"$ARGV[2].fpkm\", header=T, sep=\"\\t\")
		ggplot(dat) + geom_density(aes(x=value,color=id), size = 1.1) + labs(title = \"FPKM distribution of all samples\", x= \"log10(FPKM) of Gene\", y= \"Density\") + theme_bw()
		ggsave(\"$ARGV[2].png\")
	";
#	`Rscript $ARGV[2].r`;
#	`rm $ARGV[2].fpkm $ARGV[2].r Rplots.pdf`;

}elsif($ARGV[1] eq "filter"){
	open STAT, "> $ARGV[2].log" or die $!;
	my ($a1, $a4, $a6);
	while(<EXP>)
	{
		chomp;
		my @stat = split;
		if(/^1,/)
		{
			my $a;
			while(/(\d+\.\d+|\d+)%/)
			{
				$a += $1;
				$_ =~ s/(\d+\.\d+|\d+)%//;
			}
			$a /= 100;
			$a1 = $a;
			print STAT "Adapter\t$a\n";
		}elsif(/^4,/){
			my ($a) = $_ =~ /(\d+\.\d+|\d+)%/;
			$a /= 100;
			$a4 = $a;
			print STAT "High_N_rate\t$a\n";
		}elsif(/^6,/){
			my ($a) = $_ =~ /(\d+\.\d+|\d+)%/;
			$a /= 100;
			$a6 = $a;
			print STAT "Low_quality\t$a\n";
		}
	}
	my $cd = 1 - $a1 - $a4 - $a6;
	print STAT "Clean_Data\t$cd\n";

	open CMD, "> $ARGV[2].r" or die $!;
	my $id = basename($ARGV[2]);
	print CMD "
	dat <- read.table(\"$ARGV[2].log\", header = F, row.names = 1, sep=\"\\t\")
	png(\"$ARGV[2].pie.png\",width=800,height=600)
	color <- c(\"red\", \"yellow\", \"green\", \"blue\")
	label <- sprintf(\"%s: %2.2f%s\",row.names(dat), 100*dat[,1], \"%\")
	pie(as.numeric(100*dat[,1]), col=color,border=\"white\", labels=NA, font=1,cex=1,cex.main=2, main=\"Classification of Raw Reads($id)\")
	legend(\"bottom\",legend=label, bty=\"n\",pch=19, pt.cex=2.2,col=color, horiz=T)
	dev.off()
	";

	`Rscript $ARGV[2].r`;
	`rm $ARGV[2].r -rf`;

}else{
	die "check correct option\n";
}
