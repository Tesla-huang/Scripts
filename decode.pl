#!/usr/bin/perl -w
use strict;

#   =======================
#   XinMiao
#   xin.miao@sagene.com.cn
#   2016年 07月 19日 星期二 16:47:53 CST
#   =======================

sub usage {
	print <<USAGE;

	perl $0 -inf AAA -outf BBB
USAGE
}

use Getopt::Long;
my ( $Infile,$Outfile,$Help );
GetOptions(
	"inf:s"=>\$Infile,
	"outf:s"=>\$Outfile,
	"help"=>\$Help,
);

if ($Help || !$Infile){ &usage; die "\n"; }

open IN,"<$Infile" or die $!;
open OUT,">$Outfile" or die $!;
while (my $line = <IN>){
	my $new_line = &formatit($line);
	print OUT $new_line;
}
close IN;
close OUT;

sub formatit {
	my $value = shift;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	return $value;
}
