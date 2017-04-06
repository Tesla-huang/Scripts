#! usr/bin/perl

use strict;
use warnings;
use SVG;
die "Usage: perl $0 <fetchnew_aln> <outdir>\n" if (@ARGV != 2);
my $file1=shift;
#my $file2=shift;
my $file3=shift;#outdir 
my (%hash,%hash2,$m_len,$mark,$extra,$mRNA_start,$mRNA_end,$lncRNA_start,$lncRNA_end,$MFE,$mRNA,$lncRNA);

open IN,$file1;
#open IN2,$file2;

#==============================  search for matches  ============================#
while (<IN>)
{
	chomp;
	%hash=();
	%hash2=();
	$mRNA=$_;		## first line 
	$mRNA=~s/\>//g;
	$lncRNA=<IN>;		## second line
	chomp($lncRNA);
	$lncRNA=~s/\>//g;
	my @lnc=split /\s+/,$lncRNA;
	$lncRNA=$lnc[0];
	<IN>;			## third line
	my $str=<IN>;		## fourth line
	chomp($str);
	my @array=split /\s+/,$str;
	my ($mRNA_str,$lncRNA_str)=split /\&/,$array[0];
	my @mRNA_str=split //,$mRNA_str;

	my $j=0;
	for (my $i=0;$i<@mRNA_str;$i++)
	{
		if ($mRNA_str[$i]=~/\(/)
		{
			$j++;
			$hash{$j}=$i+1;
		}
	}

	$lncRNA_str=reverse $lncRNA_str;
	$j=0;
	my @lncRNA_str=split //,$lncRNA_str;
	for (my $i=0;$i<@lncRNA_str;$i++)
	{
		if ($lncRNA_str[$i]=~/\)/)
		{
			$j++;
			my $k=$i+1;
			$hash2{$k}=$hash{$j};
		}
	}

	if (@mRNA_str>=@lncRNA_str)
	{
		$m_len=@mRNA_str;
		$mark=0;
		$extra=@mRNA_str-@lncRNA_str;
	}
	else
	{
		$m_len=@lncRNA_str;
		$mark=1;
		$extra=@mRNA_str-@lncRNA_str;
	}
	
	my @pos = @lnc;
	($mRNA_start,$mRNA_end)=split /\,/,$pos[1];
	($lncRNA_start,$lncRNA_end)=split /\,/,$pos[3];
	$MFE=$pos[4];
	&draw("$file3/$lncRNA\_$mRNA");
}

sub draw{
#==============================  setting parameters  ============================#
my $prefix=shift;
my $width=1600;
my $height=600;

	#####  for complementary illustration #####
	### lncRNA coordinates ###
	my $lnc_x=240;
	my $lnc_y=505;
	my $lnc_w=120;
	my $lnc_h=30;

	### mRNA coordinates ###
	my $miR_x=$lnc_x;
	my $miR_y=465;
	my $miR_w=120;
	my $miR_h=30;

	######  for overall complementary  ######
	### mRNA coordinates ###
	my $grid=1000/$m_len;
	my ($mRNA_x,$mRNA_y,$mRNA_w,$mRNA_h,$lnc_X,$lnc_Y,$lnc_W,$lnc_H);
	my ($lnc_tY,$mRNA_ty);# Added to draw text of start/end correctly 2014-10-13
	my ($lnc_lY,$mRNA_ly);#	Added to draw alignment illustration correctly 2014-10-13
	if ($extra>=0)
	{
		$mRNA_x=300;
		$mRNA_y=170;
		$mRNA_w=1000;
		$mRNA_h=30;
		
		$lnc_X=$grid*$extra/2+$mRNA_x;
		$lnc_Y=$mRNA_y+100;
		$lnc_W=1000-$grid*$extra;
		$lnc_H=30;
		$lnc_tY=$lnc_Y+20+30+20;
		$mRNA_ty=$mRNA_y-20;
		$mRNA_ly=$mRNA_y+30;
		$lnc_lY=$lnc_Y;
}
	else
	{
		$extra=0-$extra;
		$lnc_X=300;
		$lnc_Y=270;
		$lnc_W=1000;
		$lnc_H=30;

		$mRNA_x=$grid*$extra/2+$lnc_X;
		$mRNA_y=$lnc_y-100;
		$mRNA_w=1000-$grid*$extra;
		$mRNA_h=30;
		$lnc_tY=$lnc_Y-20;
		$mRNA_ty=$mRNA_y+20+30+20;
		$mRNA_ly=$mRNA_y;
		$lnc_lY=$lnc_Y+30;
}


#==============================  come on, draw it  ==============================#
my $svg=SVG->new(width=>$width,height=>$height);


#==============================  overall complementary ==========================#
$svg->rect('x',$mRNA_x,'y',$mRNA_y,'width',$mRNA_w,'height',$mRNA_h,'stroke','orange','stroke-width',3,'fill','none');
$svg->rect('x',$lnc_X,'y',$lnc_Y,'width',$lnc_W,'height',$lnc_H,'stroke','blue','stroke-width',3,'fill','none');
$svg->line('x1',$mRNA_x,'y1',$mRNA_y+15,'x2',200,'y2',$mRNA_y+15,'stroke','orange','stroke-width',8) unless $mRNA_start==1;
$svg->line('x1',$mRNA_x+$mRNA_w,'y1',$mRNA_y+15,'x2',1400,'y2',$mRNA_y+15,'stroke','orange','stroke-width',8);
$svg->line('x1',$lnc_X,'y1',$lnc_Y+15,'x2',200,'y2',$lnc_Y+15,'stroke','blue','stroke-width',8);
$svg->line('x1',$lnc_X+$lnc_W,'y1',$lnc_Y+15,'x2',1400,'y2',$lnc_Y+15,'stroke','blue','stroke-width',8) unless $lncRNA_start==1;

$svg->text('x',150,'y',$mRNA_y+80,'-cdata',"MFE $MFE",'font-family','Arial','font-size',20,'stroke','black');

$svg->text('x',100-40,'y',$mRNA_y-5,'-cdata',"$mRNA",'font-family','Arial','font-size',20,'stroke','black');
$svg->text('x',100-40,'y',$lnc_Y+20+30+5,'-cdata',"$lncRNA",'font-family','Arial','font-size',20,'stroke','black');
$svg->text('x',$mRNA_x,'y',$mRNA_ty,'-cdata',$mRNA_start,'font-family','Arial','font-size',20,'stroke','orange','fill','orange');
$svg->text('x',$mRNA_x+$mRNA_w,'y',$mRNA_ty,'-cdata',$mRNA_end,'font-family','Arial','font-size',20,'stroke','orange','fill','orange');
$svg->text('x',$lnc_X,'y',$lnc_tY,'-cdata',$lncRNA_end,'font-family','Arial','font-size',20,'stroke','blue','fill','blue');
$svg->text('x',$lnc_X+$lnc_W,'y',$lnc_tY,'-cdata',$lncRNA_start,'font-family','Arial','font-size',20,'stroke','blue','fill','blue');

for my $key(sort {$a<=>$b} keys %hash2)
{
	$svg->line('x1',$mRNA_x+$grid*$hash2{$key},'y1',$mRNA_ly,'x2',$lnc_X+$grid*$key,'y2',$lnc_lY,'stroke','red','stroke-width',$grid);
	$svg->line('x1',$mRNA_x+$grid*$hash2{$key},'y1',$mRNA_y+30,'x2',$mRNA_x+$grid*$hash2{$key},'y2',$mRNA_y,'stroke','orange','stroke-width',$grid);
	$svg->line('x1',$lnc_X+$grid*$key,'y1',$lnc_Y,'x2',$lnc_X+$grid*$key,'y2',$lnc_Y+30,'stroke','blue','stroke-width',$grid);
}



#==============================  complementary illustration =====================#

### complementary rectangle ###
my ($path_x2,$path_y2,$path_x3,$path_y3,$path_x4,$path_y4,$path_x5,$path_y5,$path_x6,$path_y6);
my $path_x1=100;
my $path_y1=550;
for (my $i=4;$i<4;$i++)
{
	
	### four blocks ###
	if ($i==0)
	{
		$lnc_x=$lnc_x;
		$lnc_y=$lnc_y;
	}elsif($i==1)
	{
		$lnc_x=$lnc_x+300;
		$lnc_y=$lnc_y+50;
		$miR_y=$miR_y+50;
	}elsif($i==2)
	{
		$lnc_x=$lnc_x+400;
		$lnc_y=$lnc_y-50;
		$miR_y=$miR_y-50;
	}else
	{
		$lnc_x=$lnc_x+300;
		$lnc_y=$lnc_y+50;
		$miR_y=$miR_y+50;
	}
	$miR_x=$lnc_x;

	### curve coordinates ###
	$path_x2=$path_x1+50;	$path_y2=$lnc_y-50;
	$path_x3=$path_x1+50;	$path_y3=$path_y1-20;
	$path_x4=$path_x1+75;	$path_y4=$path_y1-10;
	$path_x5=$lnc_x-25;	$path_y5=$path_y1-20;
	$path_x6=$lnc_x;	$path_y6=$lnc_y+15;
	$svg->rect('x',$lnc_x,'y',$lnc_y,'width',$lnc_w,'height',$lnc_h,'stroke','blue','stroke-width',1,'fill','blue');
	$svg->rect('x',$miR_x,'y',$miR_y,'width',$miR_w,'height',$miR_h,'stroke','orange','stroke-width','1','fill','orange');
	$svg->path('d',"M$path_x1,$path_y1 C$path_x2,$path_y2 $path_x3,$path_y3 $path_x4,$path_y4 S$path_x5,$path_y5 $path_x6,$path_y6",'fill','none','stroke-width',4,'stroke','blue');
	$path_y1=$path_y1-40;$path_y2=$path_y2-60;$path_y3=$path_y3-80;$path_y4=$path_y4-60;$path_y5=$path_y5-80;$path_y6=$path_y6-40;
	$svg->path('d',"M$path_x1,$path_y1 C$path_x2,$path_y2 $path_x3,$path_y3 $path_x4,$path_y4 S$path_x5,$path_y5 $path_x6,$path_y6",'fill','none','stroke-width',4,'stroke','orange');
	if ($i==0)
	{
		$svg->circle('cx',$path_x1,'cy',$path_y1,'r',7,'stroke','orange','fill','orange');
		$svg->text('x',$path_x1-30,'y',$path_y1-30,'-cdata','Cap','font-family','Arial','font-size',20,'stroke','orange');
	}
	$path_x1=$lnc_x+120;$path_y1=$lnc_y+15;
}


### last curve ### 
#$path_y2=$path_y2+60;$path_y3=$path_y3+80;$path_y4=$path_y4+60;$path_y5=$path_y5+80;$path_y6=$path_y6+40;
#$path_x2=$path_x1+50;$path_x3=$path_x1+50;$path_x4=$path_x1+70;$path_x5=$path_x1+110;
#$path_x6=1480;$path_y6=570;
#$svg->path('d',"M$path_x1,$path_y1 C$path_x2,$path_y2 $path_x3,$path_y3 $path_x4,$path_y4 S$path_x5,$path_y5 $path_x6,$path_y6",'fill','none','stroke-width',4,'stroke','blue');
#$path_y1=$path_y1-40;$path_y2=$path_y2-60;$path_y3=$path_y3-80;$path_y4=$path_y4-60;$path_y5=$path_y5-80;$path_y6=$path_y6-40;
#$path_x6=1550;$path_y6=430;
#$svg->path('d',"M$path_x1,$path_y1 C$path_x2,$path_y2 $path_x3,$path_y3 $path_x4,$path_y4 S$path_x5,$path_y5 $path_x6,$path_y6",'fill','none','stroke-width','4','stroke','orange');
#$svg->text('x',$path_x6-50,'y',$path_y6,'-cdata','AAAAA','font-family','Arial','font-size',20,'stroke','orange');


	### text ###
#	my $miR5p_x=100;	my $miR5p_y=420;
#	my $miR3p_x=1500;	my $miR3p_y=420;
#	my $lnc5p_x=$miR5p_x;	my $lnc5p_y=580;
#	my $lnc3p_x=1500;	my $lnc3p_y=580;
#	$svg->text('x',$miR5p_x,'y',$miR5p_y,'-cdata','5P','font-family','Arial','font-size',30,'stroke','orange','fill','orange');
#	$svg->text('x',$miR3p_x,'y',$miR3p_y,'-cdata','3P','font-family','Arial','font-size',30,'stroke','orange','fill','orange');
#	$svg->text('x',$lnc5p_x,'y',$lnc5p_y,'-cdata','3P','font-family','Arial','font-size',30,'stroke','blue','fill','blue');
#	$svg->text('x',$lnc3p_x,'y',$lnc3p_y,'-cdata','5P','font-family','Arial','font-size',30,'stroke','blue','fill','blue');

$prefix=~s/\|/\_/;	#Added 2014-10-22 : For wierd fasta headers that contain "|"; Changed "|" to "_" for compatibility with Windows
open OUT,">$prefix.svg";
print OUT $svg->xmlify();
close OUT;
#$prefix=~s/\|/\\\|/;	#Added 2014-10-22 : For wierd fasta headers that contain "|"; The "|" will be changed to "_" when you un-tar in Windows.
###TH2#system "/HOME/sysu_luoda_1/bin/rsvg-convert $prefix.svg -o $prefix.png";###
system "/usr/bin/rsvg-convert $prefix.svg -o $prefix.png";

#==============================  help document  =================================#
}
