#!/usr/bin/perl

=head1 Name

 annot2wego.pl

=head1 Description

 convert blast2go result from '.annot' to '.wego'.

=head1 Author

 He Zengquan Email: hezengquan@genomics.org.cn

=head1 Version

 Version: 1.0,  Date: 2009-06-12

=head1 Usage

  -i		blast2go result file. '*.annot'
  -o		output file for wego
  -help		Output help information to screen

=head1 Example

 perl annot2wego.pl  -i ss.annot 
 perl annot2wego.pl  -i ss.annot -o ss.wego

=cut

use strict;
use Getopt::Long;

my ($infile,$outfile,$Verbose,$Help);
GetOptions(
	"i:s"=>\$infile,
	"o:s"=>\$outfile,
	"verbose!"=>\$Verbose,
	"h|help"=>\$Help
);

die `pod2text $0` if ($Help||!$infile);

################### main function #####################

my %hash;

open (STDIN,'<',$infile) || die "Can't open $infile!\n";
while (<STDIN>) {
	next if($_ eq "\n");
	chomp;
	my @temp=split /\t+/,$_;
	if (exists $hash{$temp[0]}) {
		$hash{$temp[0]}.="\t$temp[1]";
	}
	else{
		$hash{$temp[0]}=$temp[1];
	}
}
close STDIN;

open (STDOUT,'>',$outfile) || die "Can't create $outfile!\n";
foreach my $k(sort keys %hash) {
	print STDOUT "$k\t$hash{$k}\n";
}
close STDOUT;


########################################################
