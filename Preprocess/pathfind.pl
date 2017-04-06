#!/usr/bin/perl -w

=pod
description: pathfind
author: Zhang Fangxian, zhangfx@genomics.cn
created date: 20090706
modified date: 20100806, 20100430, 20091211, 20091204, 20091127, 20091119, 20091012, 20090929, 20090917, 20090820, 20090810, 20090805, 20090727, 20090710
=cut

use Getopt::Long;
use FindBin '$Bin';
use File::Basename 'dirname';

our ($fg, $bg, $koMap, $output, $help);

GetOptions(
	"fg:s" => \$fg,
	"bg:s" => \$bg,
	"komap:s" => \$koMap,
	"output:s" => \$output,
	"help|?" => \$help,
);
$output ||= "./out.path";
##############added by dushuo 2010-11-3
my $name;
$name = (split /[\\\/]/, $output)[-1];
$name =~ s/\.path$//;
######
if (defined $koMap) {
	$koMap0 = $koMap;
}

our ($kegg, $mapTitle);
do "$Bin/keggConf.pl" || die $!;
$koMap2 = $koMap;

if (defined $koMap0) {
	$koMap = $koMap0;
}

sub usage {
	print STDERR << "USAGE";
description: pathfind
usage: perl $0 [options]
options:
	-fg: foreground ko file
	-bg: background ko file, or 3 small-caption letters for species
	-komap: ko_map.tab file, default is $koMap2
	-output: output file, default is out.path
	-help: help information
e.g.:
	perl $0 -fg ko -output out.path
	perl $0 -fg 1.ko -bg 2.ko -output out.path
	perl $0 -fg 1.ko -bg hsa -output out.path
USAGE
}

if (defined $help || !defined $fg) {
	&usage();
	exit 1;
}

if (defined $bg && !-f $bg && length($bg) == 3) {
	$bg =~ tr/[A-Z]/[a-z]/;
	open KO, "< $kegg" || die $!;
	open BG, "> $bg.ko" || die $!;
	while (<KO>) {
		chomp;
		next unless (/^>$bg.*[\s;]\sK\d+/);
		$_ =~ s/^>$bg://;
		@tabs = split /\s/, $_, 2;
		$tabs[1] = " $tabs[1]";
		$tabs[1] =~ s/([ ;]) [^K][^;]*\s;/$1/g;
		$tabs[1] =~ s/; (K[\d]+)/\|$1/g;
		$tabs[1] =~ s/^ *//;
		@ids = ();
		for (split /\|/, $tabs[1]) {
			$_ =~ s/^\s*//;
			@tabs2 = split / /, $_, 2;
			$id = $tabs2[0];
			push @ids, $id if ($id =~ /^K\d+/);
		}
		print BG "$tabs[0]\t" . (join "!", @ids) . "\n";
	}
	close BG;
	close KO;

	if (!defined $koMap0 || !-f $koMap0) {
		$koMap = "$bg\_ko_map.tab";
		system("perl $Bin/genKOMap.pl -species $bg -output $koMap");
	}

	$bg .= ".ko";
	$koMap = $koMap2 if (-s $koMap == 0);
}

# check input files
push @inputs, $fg;
push @inputs, $bg if (defined $bg);
$koMap = $koMap2 if (!defined $koMap || !-f $koMap);

my $exit = 0;
for $file (@inputs, $koMap, $mapTitle) {
	if (!-f $file) {
		print STDERR "file $file not exists\n";
		$exit = 1;
	}
}

exit 1 if ($exit == 1);

# main
local($/);

open IN, "< $koMap" || die $!;
$all_in = <IN>;
$all_in =~ s/\n+$//;
close IN;
@all_ins = split /\n/, $all_in;
for $line (@all_ins) {
	@temp = split /\t/, $line;
	@{$kos{$temp[0]}} = split /\s/, $temp[1];
}

open IN, "< $mapTitle" || die $!;
$all_in = <IN>;
$all_in =~ s/\n+$//;
close IN;
@all_ins = split /\n/, $all_in;
for $line (@all_ins) {
	@temp = split /\t/, $line;
	$titles{$temp[0]} = $temp[1];
}

undef($all_in);
undef(@all_ins);
local($/) = "\n";

open FG, "< $fg" || die $!;
%genes1 = ();
%genes2 = ();
$sum1 = 0;
$sum2 = 0;
while (<FG>) {
	chomp;
	next if ($_ eq "" or index($_, "#") == 0);
	@temp = split /\t/, $_;
	next if ($#temp == 0);
	$temp[1] =~ s/\|[^!]*!*/!/g;
	$temp[1] =~ s/!$//;
	@temp2 = split /!/, $temp[1];
	if (!exists $genes1{$temp[0]}) {
		$sum1++;
		$genes1{$temp[0]} = 1;
	}
	for $KO (@temp2) {
		if (exists $kos{$KO}) {
			for $ko (@{$kos{$KO}}) {
				if (exists $titles{$ko}) {
					if (!exists $stats{$ko}) {
						$stats{$ko}{"pathway"} = $titles{$ko};
						$stats{$ko}{"genes"} = [];
						$stats{$ko}{"kos"} = [];
						if (defined $bg) {
							$stats{$ko}{"genes2"} = [];
							$stats{$ko}{"kos2"} = [];
						}
					}
					push @{$stats{$ko}{"genes"}}, $temp[0] if (index("," . (join ",", @{$stats{$ko}{"genes"}}) . ",", "," . $temp[0] . ",") == -1);
					push @{$stats{$ko}{"kos"}}, $KO if (index("," . (join ",", @{$stats{$ko}{"kos"}}) . ",", "," . $KO . ",") == -1);
				}
			}
		}
	}
}
close FG;

if (!defined $bg) { # case 1: without background
	$num = 0;
	$content = "";
	for $pwID (sort {$#{$stats{$b}{"genes"}} <=> $#{$stats{$a}{"genes"}}} keys %stats) {
		$num = @{$stats{$pwID}{"genes"}};
		$content .= "$stats{$pwID}{'pathway'}\t" . $num . "\tko$pwID\t" . (join ";", @{$stats{$pwID}{"genes"}}) . "\t" . (join "+", @{$stats{$pwID}{"kos"}}) . "\n";
	}
	open OUT, "> $output" || die $!;
	print OUT "#Pathway\tCount (" . $sum1 . ")\tPathway ID\tGenes\tKOs\n";
	print OUT $content;
	close OUT;
} else { # case 2: with background
	open BG, "< $bg" || die $!;
	while (<BG>) {
		chomp;
		next if ($_ eq "" or index($_, "#") == 0);
		@temp = split /\t/, $_;
		next if ($#temp < 1);
		$temp[1] =~ s/\|[^!]*!*/!/g;
		$temp[1] =~ s/!$//;
		@temp2 = split /!/, $temp[1];
		if (!exists $genes2{$temp[0]}) {
			$sum2++;
			$genes2{$temp[0]} = 1;
		}
		for $KO (@temp2) {
			if (exists $kos{$KO}) {
				for $ko (@{$kos{$KO}}) {
					if (exists $titles{$ko}) {
						next if (!exists $stats{$ko});
						push @{$stats{$ko}{"genes2"}}, $temp[0] if (index("," . (join ",", @{$stats{$ko}{"genes2"}}) . ",", "," . $temp[0] . ",") == -1);
						push @{$stats{$ko}{"kos2"}}, $ko if (index("," . (join ",", @{$stats{$ko}{"kos2"}}) . ",", "," . $ko . ",") == -1);
					}
				}
			}
		}
	}
	close BG;

	$num1 = 0;
	$num2 = 0;
	$content = "";

	open PT, "> ptemp.R" || die $!;
	for $pwID (sort keys %stats) {
		$num1 = @{$stats{$pwID}{"genes"}};
		$num2 = @{$stats{$pwID}{"genes2"}};
		print PT "phyper($num1 - 1, $num2, $sum2 - $num2, $sum1, lower.tail=F)\n";
	}
	close PT;
    $Rscript = "/Bio/bin/Rscript" if (-x "/Bio/bin/Rscript"); ##added at 2011-12-21
	@pValues = split /\n/, `$Rscript ptemp.R | awk '{print \$2}' 2> /dev/null`;

	$p = join(", ", @pValues);
	open QT, "> qtemp.R" || die $!;
	print QT <<QT;
library(qvalue)
p <- c($p)
q <- qvalue(p, lambda = 0)
q[3]
QT
	close QT;
#	$Rscript = "Rscript";
#	$Rscript = "/share/raid1/genome/biosoft/R-2.9.1/bin/Rscript" if (-x "/share/raid1/genome/biosoft/R-2.9.1/bin/Rscript");
	@qValues = split /\n/, `$Rscript qtemp.R 2> /dev/null | awk 'NR > 1 {for (x = 2; x <= NF; x++) print \$x}'`;
#	unlink "ptemp.R", "qtemp.R";

	$i = 0;
	for my $pwID (sort keys %stats) {
		$stats{$pwID}{"pvalue"} = $pValues[$i];
		$stats{$pwID}{"qvalue"} = $qValues[$i];
		$i++;
	}

	for $pwID (sort {$stats{$a}{"pvalue"} <=> $stats{$b}{"pvalue"}} keys (%stats)) {
	#for $pwID (sort keys %stats){
		print STDOUT $stats{$pwID}{"pvalue"},"\n";
		$num1 = @{$stats{$pwID}{"genes"}};
		$num2 = @{$stats{$pwID}{"genes2"}};
		$content .= "$stats{$pwID}{'pathway'}\t" . $num1 . "\t" . $num2 . "\t$stats{$pwID}{'pvalue'}\t$stats{$pwID}{'qvalue'}\tko$pwID\t" . (join ";", @{$stats{$pwID}{"genes"}}) . "\t" . (join "+", @{$stats{$pwID}{"kos"}}) . "\n";
	}
	open OUT, "> $output" || die $!;
#	print OUT "#Pathway\tSample1 (" . $sum1 . ")\tSample2 (" . $sum2 . ")\tPvalue\tQvalue\tPathway ID\tGenes\tKOs\n";##deleted by dushuo 2010-11-3
	print OUT "#Pathway\t$name (" . $sum1 . ")\tAll-Unigene (" . $sum2 . ")\tPvalue\tQvalue\tPathway ID\tGenes\tKOs\n";########added by dushuo 2010-11-3
	print OUT $content;
	close OUT;
}

exit 0;
