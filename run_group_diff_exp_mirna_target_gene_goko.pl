#!usr/bin/perl -w
use strict;
use Getopt::Std;
use Cwd 'abs_path';
use FindBin qw($Bin $Script);
use lib $Bin;

use vars qw($opt_c $opt_D $opt_T $opt_p $opt_k $opt_g $opt_s $opt_d $opt_t $opt_o $opt_h);
getopts('c:D:T:p:k:g:s:d:t:o:h');

my $con_pair  = $opt_c;
my $diff_dir  = $opt_D;
my $target_file = $opt_T;
my $pvalue    = $opt_p;
my $flag_go   = $opt_g;
my $flag_ko   = $opt_k;
my $species   = $opt_s;
my $sdir      = $opt_d;
my $type      = $opt_t;
my $out       = $opt_o;
my $help      = $opt_h ? 1:0;

print STDERR "\ncompare\t$con_pair\ndirr_exp_directory\t$diff_dir\ntarget_prediction_file\t$target_file\nPvalue\t$pvalue\ngo\t$flag_go\nko\t$flag_ko\nspecies\t$species\nsdir\t$sdir\ntype\t$type\noutput\t$out\n\n";

unless(-e $diff_dir && -e $target_file) { &usage(); exit; }
if($help) { &usage(); exit; }

my $program = $Bin;
mkdir $out unless(-d $out);

chdir $out;
my @a=split(/:/,$con_pair);
my $pair=join"_vs_",@a;
my %diff_mirna;

open(DIFF,"$diff_dir/$pair/$a[0]_vs_$a[1].exp.AOV.xls")||die"cannot open:$!";
while(<DIFF>) {
	chomp;   my @b=split(/\t/,$_);
	if($.==1) { next; }
	else {
		if(($b[-2]<-1||$b[-2]>1) && $b[-1] < $pvalue) {
			$diff_mirna{$b[0]}=$_;
		}
	}
}

print STDERR "compare ",$pair," diff exp miRNA: \n",(join",",(keys %diff_mirna)),"\n\n";
if(scalar keys %diff_mirna==0){
	print STDERR "no group diff mirna,so quit\n";
	exit(0);
}
close DIFF;
my %glist;

open(TARGET,$target_file)||die"cannot open:$!";
while(<TARGET>) {
	if(/^>/) {
		my @b=split(/\t/,$_);   $b[0]=~s/>//;
		if($type==0 || $type==1) {
			$glist{$b[2]}++ if (exists $diff_mirna{$b[0]});
		} else {
			print STDERR "worong type ,please  inpute -t 1 or -t 0\n";
		}
	}
}
close TARGET;

open(GLIST,">$pair.glist")||die"cannot open:$!";
foreach my $out(keys %glist) {
	print GLIST "$out\n";
}
close GLIST;

#system "LD_LIBRARY_PATH_old=\$LD_LIBRARY_PATH";
#$ENV{'LD_LIBRARY_PATH_old'}=$ENV{'LD_LIBRARY_PATH'};
##system "LD_LIBRARY_PATH_new=/Bio/User/luoyue/gcc-4.9.2/lib64:\$LD_LIBRARY_PATH";
#$ENV{'LD_LIBRARY_PATH_new'}="/Bio/User/luoyue/gcc-4.9.2/lib64:".$ENV{'LD_LIBRARY_PATH'};
##system "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH_new";
#$ENV{'LD_LIBRARY_PATH'}=$ENV{'LD_LIBRARY_PATH_new'};

if($flag_ko) {
	chdir $out;
	print STDERR "run $pair ko\t current directory: \n",`pwd`,"\n";
	if(-e "$sdir/$species.kopath") {
		system "mkdir -p KO" unless (-d "KO");
		system "mkdir -p KO/$pair" unless(-d "KO/$pair");
		chdir "KO/$pair";

		system "mkdir -p ../../$pair\_glist" unless (-d "../../$pair\_glist");
		system "mv ../../$pair.glist ../../$pair\_glist";

#		system"perl $program/getKO.pl -glist ../../$pair\_glist/$pair.glist -bg $sdir/$species.ko -outdir ./";
		system "perl /Bio/Pipeline/Module/easyEnrich/bin/KO/keggpath.pl PATH -f ../../$pair\_glist/$pair.glist -b $sdir/$species.kopath -o $pair";
		system "perl /Bio/Pipeline/Module/easyEnrich/bin/KO/KEGG_Gradient.pl $pair.path.xls 20 Q";
		system "perl /Bio/Pipeline/Module/easyEnrich/bin/KO/keggMap_nodiff.pl -ko $pair.kopath -outdir $pair\_map";
		system "mv $pair.kopath $pair.kopath.xls";
		system "perl /Bio/Pipeline/Module/easyEnrich/bin/KO/genPathHTML_v2.pl -indir .";

#		my $ko_map_dir="/Bio/Database/Database/kegg/data/map_class";
#		if($type == 0) {
#			my $an="$ko_map_dir/animal_ko_map.tab";
#			system"perl $program/pathfind.pl -komap $an -fg $pair.ko -bg $sdir/$species.ko -output ./$pair.path";
#			system"perl $program/keggGradient.pl ./$pair.path 20";
#			system"perl $program/keggMap_nodiff.pl  -komap $an -ko $pair.ko -outdir ./$pair\_map";
#		}elsif($type == 1) {
#			my $pl="$ko_map_dir/plant_ko_map.tab";
#			system"perl $program/pathfind.pl -komap $pl -fg $pair.ko -bg $sdir/$species.ko -output ./$pair.path";
#			system"perl $program/keggGradient.pl ./$pair.path 20";
#			system"perl $program/keggMap_nodiff.pl -komap $pl -ko $pair.ko -outdir ./$pair\_map";
#		}

#		unless (-d "$pair\_map") { system"mkdir $pair\_map"; }

#		system"perl $program/genPathHTML.pl -indir ./";

#		system"perl /home/miaoxin/Pipeline/RNA_Seq/RNAseq_Programs/add_B_class.pl -indir .";
		chdir "../../";
	} else {
		print STDERR "$sdir/$species.ko: No such file or directory!\n";
		exit;
	}
}

if($flag_go) {
	chdir $out;
	print STDERR "run $pair go\t current directory: \n",`pwd`,"\n";
	if(-e "$sdir/$species.C" && -e "$sdir/$species.F" && -e "$sdir/$species.P") {
		system "mkdir -p GO" unless (-d "GO");
		system "mkdir -p GO/$pair" unless(-d "GO/$pair");
		chdir "GO/$pair";
		if(-d "../../$pair\_glist") {
			if(-e "../../$pair.glist") {
				system "mv ../../$pair.glist ../../$pair\_glist";
			}
		} else {
			system "mkdir -p ../../$pair\_glist";
			system "mv ../../$pair.glist ../../$pair\_glist";
		}
		system "perl /Bio/Pipeline/Module/easyEnrich/bin/GO/EnrichGO.pl -fg ../../$pair\_glist/$pair.glist -bg $sdir/$species.bgl -a $sdir/$species -op $pair -ud nodiff";
#		system("perl $program/getGO.pl ../../$pair\_glist/$pair.glist $sdir/$species.wego > ../../$pair\_glist/$pair.wego");
#		system("perl $program/drawGO_sort.pl -gglist ../../$pair\_glist/$pair.wego -output ./$pair.wego");
#		system("/usr/bin/rsvg-convert ./$pair.wego.svg -o ./$pair.wego.png");
#		system"perl $program/functional_nodiff.pl -go -gldir ../../$pair\_glist -sdir $sdir -species $species -outdir ./";
#		if(-d "GO"){ system"mv GO/* ."; system"rm -rf GO"; system"rm -rf GOView.html GOViewList.html";}
		chdir "../../";
	} else {
		print STDERR "The background files for GO annotation are not complete!";
		exit;
	}
}

#system "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH_old";
#$ENV{'LD_LIBRARY_PATH'}=$ENV{'LD_LIBRARY_PATH_old'};

unless ($flag_ko || $flag_go)
{
	print "Please provide the analysis you need with -k or -g!\n";
	&usage();
	exit;
}

sub usage {
	my $usage = << "USAGE";
get the KO and GO annotation
Version: 1.0
user chgao\@genedenovo.com
Copyright: All rights conserved
Usage: run_group_diff_exp_mirna_target_gene_goko.pl
	-c <list> sample compare list eg con:treat
	-D <directory> group_diff exp miRNA directory absolute path forced
	-T <file>  target prediction file forced
	-p <float> pvalue 0.05-significant  ,  0.01-super significant.
	-k <num> flag for KO analysis. 1 for analyze, 0 for not analyze.
	-g <num> flag for GO analyssi. 1 for analyze, 0 for not analyze.
	-s <string> species name, prefix of .[FCP] files and .ko file
	-d <string> directory including .[FCP] files and .ko file
	-t <num> Type: 0-animal,1-plant
	-o <string> output directory, absolute path forced
	-h Help
USAGE
print $usage;
exit;
}
