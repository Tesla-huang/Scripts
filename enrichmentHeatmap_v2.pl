#!perl
use warnings;
use strict;
use File::Basename qw(basename);

die "perl $0 <input dir> <go or kegg>\n" if @ARGV != 2;

my $convert = `which convert`;
chomp($convert);
print STDERR "couldn't find convert in the system path, will not convert pdf to png!!!\n" unless (-s "$convert");

if($ARGV[1] eq "go")
{
	my @files = `ls $ARGV[0]/*.P.xls $ARGV[0]/*.F.xls $ARGV[0]/*.C.xls`;

	my (%hash, %all, %name);

	foreach my $i(@files)
	{
		chomp($i);
		my $test = `wc -l $i`;
		next if ($test =~ /^1 /);
		open FA, $i or die $!;
		<FA>;
		$i = basename($i);
		next if($i !~ /[PFC]\.xls$/);
		my ($id, $type) = $i =~ /^(\S+)\.([PFC])\.xls$/;
		$name{$id} = 0;
		my $t;
		if($type eq "P")
		{
			$t = "Biological Process";
		}elsif($type eq "F"){
			$t = "Molecular Function";
		}else{
			$t = "Cellular Component";
		}
		while(my $line = <FA>)
		{
			chomp($line);
			my @tmp = split /\t/, $line;
			my ($fz) = $tmp[2] =~ /^(\d+)\D*/;
			my ($fm) = $tmp[3] =~ /^(\d+)\D*/;
			my $rf = $fz / $fm;
			$hash{$id}{"$t\t$tmp[1]"}{rf} =  $rf;
			$hash{$id}{"$t\t$tmp[1]"}{pv} =  $tmp[4];
			$hash{$id}{"$t\t$tmp[1]"}{qv} =  $tmp[5];
			$all{"$t\t$tmp[1]"} = 0;
		}
		close FA;
	}

	open RF, "> $ARGV[0]/rf.$ARGV[1]" or die $!;
	open PV, "> $ARGV[0]/pv.$ARGV[1]" or die $!;
	open QV, "> $ARGV[0]/qv.$ARGV[1]" or die $!;

	my @n = sort keys %name;

	print RF "Type\tTerm\t".join("\t", @n)."\n";
	print PV "Type\tTerm\t".join("\t", @n)."\n";
	print QV "Type\tTerm\t".join("\t", @n)."\n";

	foreach(sort keys %all)
	{
		my ($lrf, $lpv, $lqv);
		foreach my $i(sort keys %hash)
		{
			if(exists $hash{$i}{$_})
			{
				$lrf .= "$hash{$i}{$_}{rf}\t";
				$lpv .= "$hash{$i}{$_}{pv}\t";
				$lqv .= "$hash{$i}{$_}{qv}\t";
			}else{
				$lrf .= "NA\t";
				$lpv .= "NA\t";
				$lqv .= "NA\t";
			}
		}
		$lrf =~ s/\t$/\n/;
		$lpv =~ s/\t$/\n/;
		$lqv =~ s/\t$/\n/;
		print RF "$_\t$lrf";
		print PV "$_\t$lpv";
		print QV "$_\t$lqv";
	}
}elsif($ARGV[1] eq "kegg"){
	my @files = `ls $ARGV[0]/*\.path\.xls`;

	my (%hash, %all, %name, %pw);

	foreach my $i(@files)
	{
		chomp($i);
		my $test = `wc -l $i`;
		next if($test =~ /^1 /);
		open FA, $i or die $!;
		<FA>;
		$i = basename($i);
		my ($id) = $i =~ /^(\S+)\.path\.xls$/;
		$name{$id} = 0;
		while(my $line = <FA>)
		{
			chomp($line);
			my @tmp = split /\t/, $line;
#			my $rf = $tmp[3] / $tmp[4];
			my $rf = $tmp[3];
			$hash{$id}{"$tmp[1]\t$tmp[2]"}{rf} =  $rf;
			$hash{$id}{"$tmp[1]\t$tmp[2]"}{pv} =  $tmp[5];
			$hash{$id}{"$tmp[1]\t$tmp[2]"}{qv} =  $tmp[6];
			$all{"$tmp[1]\t$tmp[2]"} = 0;
		}
		close FA;
	}
	
	open RF, "> $ARGV[0]/rf.$ARGV[1]" or die $!;
	open PV, "> $ARGV[0]/pv.$ARGV[1]" or die $!;
	open QV, "> $ARGV[0]/qv.$ARGV[1]" or die $!;

	my @n = sort keys %name;

	print RF "B_Pathway\tC_Pathway\t".join("\t", @n)."\n";
	print PV "B_Pathway\tC_Pathway\t".join("\t", @n)."\n";
	print QV "B_Pathway\tC_Pathway\t".join("\t", @n)."\n";

	foreach(sort keys %all)
	{
		my ($lrf, $lpv, $lqv);
		foreach my $i(sort keys %hash)
		{
			if(exists $hash{$i}{$_})
			{
				$lrf .= "$hash{$i}{$_}{rf}\t";
				$lpv .= "$hash{$i}{$_}{pv}\t";
				$lqv .= "$hash{$i}{$_}{qv}\t";
			}else{
				$lrf .= "NA\t";
				$lpv .= "NA\t";
				$lqv .= "NA\t";
			}
		}
		$lrf =~ s/\t$/\n/;
		$lpv =~ s/\t$/\n/;
		$lqv =~ s/\t$/\n/;
		print RF "$_\t$lrf";
		print PV "$_\t$lpv";
		print QV "$_\t$lqv";
	}
}else{
	die "choose correct options: go or kegg";
}

my @files;
if($ARGV[1] eq "go")
{
	@files = `ls $ARGV[0]/*.go`;
}else{
	@files = `ls $ARGV[0]/*.kegg`;
}

foreach(@files)
{
	chomp;

	my $rf = 0;
	my $filename = basename($_);
	if($_ =~ /rf/)
	{
		$rf = 0.05;
	}
	open FA, "$_" or die $!;
	open TMP, "> $_.tmp" or die $!;
	my $head = <FA>;
	print TMP $head;
	while(my $line = <FA>)
	{
		chomp($line);
		my @tmp = split /\t/, $line;
		my @num = @tmp[2..$#tmp];
		my $n = 0;
		foreach my $i(@num)
		{
			next if($i eq "NA");
			if($rf == 0)
			{
				$n ++ if($i <= 0.05);
			}else{
				$n ++ if($i >= $rf);
			}
		}
		if($n > 0)
		{
			print TMP "$line\n";
		}
	}
	close FA;
	close TMP;

	my $test = `wc -l $_.tmp`;
	unless($test =~ /^1 /){
	open CMD, "> $ARGV[0]/$ARGV[1].r" or die $!;
	print CMD "
	library(pheatmap)
	rawdata = read.table(\"$_.tmp\", header = T, sep = \"\\t\", quote =\"\", check.names = F)
	mat = data.frame(rawdata[,3:length(colnames(rawdata))])
	rownames(mat) = rawdata[,2]
	colnames(mat) = colnames(rawdata)[3:length(colnames(rawdata))]
	matmp = as.matrix(mat)
	matmpx = arrayInd(order(matmp,decreasing=TRUE)[1:1],dim(matmp))
	matx = mat[matmpx[1,1],matmpx[1,2]]
	matmpi = arrayInd(order(matmp,decreasing=FALSE)[1:1],dim(matmp))
	mati = mat[matmpi[1,1],matmpi[1,2]]
	annot = data.frame(class=rawdata[,1])
	rownames(annot)= rownames(mat)
	if (matx > mati)
	{
		if (matx > 0.05)
		{
			bias = (matx/0.05)-1
			if(\"$filename\" == \"rf.go\" || \"$filename\" == \"rf.kegg\")
			{
				mycolor = colorRampPalette(c(\"green\", \"white\", \"red\"),bias=bias)(256)
			}else{
				mycolor = colorRampPalette(c(\"red\", \"white\", \"green\"),bias=bias)(256)
			}
			pheatmap(mat, legend_breaks=c(0, 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, 1), cluster_cols=F, cluster_rows=F, color=mycolor, display_numbers=T, annotation_row=annot, number_format=\"%.3f\",filename=\"$_.pdf\",cellwidth=25,cellheight=12)
		}else{
			if(\"$filename\" == \"rf.go\" || \"$filename\" == \"rf.kegg\")
			{
				mycolor = colorRampPalette(c(\"green\", \"white\"))(256)
			}else{
				mycolor = colorRampPalette(c(\"red\", \"white\"))(256)
			}
			pheatmap(mat, legend_breaks=c(0, 0.01, 0.025, 0.05), cluster_cols=F, cluster_rows=F, color=mycolor, display_numbers=T, annotation_row=annot, number_format=\"%.3f\",filename=\"$_.pdf\",cellwidth=25,cellheight=12)
		}
	}";

	`Rscript $ARGV[0]/$ARGV[1].r`;
	`rm Rplots.pdf -rf`;
	`convert $_.pdf $_.png` if ($convert && -s "$convert");
	}
	`mv $_.tmp $_.xls -f`;
}

#`rm $ARGV[0]/*.$ARGV[1] -rf`;
#`rm $ARGV[0]/*.r -rf `;
