#! /usr/bin/perl

use utf8;
use strict;
use warnings;
#use Getopt::Long;
#use Bio::SeqIO;
#use Bio::Seq;
#use List::Util qw/sum min max/;
#use File::Basename qw/basename dirname/;
#use File::Spec::Functions qw/rel2abs/;
#use FindBin qw/$Bin $Script/;
#use lib $Bin;

die "perl $0 <origin_file(fa/table)> <id_col_n.o.> <id2id_file(two columes, name2chr/tr2gene)> <fa|txt(OriginFileType)> <in.sep(s|t)\nstdout\n" unless(@ARGV eq 5);

open IN, "$ARGV[0]" or die $!;
open ID, "$ARGV[2]" or die $!;

my %hash;

while (<ID>) {
	chomp;
	my @tmp = split /\t/, $_;
	$hash{$tmp[0]} = $tmp[1];
}
close ID;

my $cn = $ARGV[1] - 1;
while (<IN>) {
	chomp;
#	$_ =~ s/^\s+//g;
	unless (/^\n$/) {
		my @tmp;
		if ($ARGV[4] eq "t") {
			@tmp = split /\t/, $_;
		}else{
			@tmp = split /\s+/, $_;
		}
		if ($tmp[$cn]) {
			my $name = $tmp[$cn];
			$name =~ s/^>// if ($ARGV[3] =~ /fa/i);
			if (exists $hash{$name}) {
				print ">" if ($ARGV[3] =~ /fa/i);
				$tmp[$cn] = $hash{$name};
				my $text = "xxx";
				$text = join(" ", @tmp) if ($ARGV[4] eq "s");
				$text = join("\t",@tmp) if ($ARGV[4] eq "t");
				print "$text\n";
			}else{
				print "$_\n";
			}
		}else{
			print "$_\n";
		}
	}else{
		print "$_\n";
	}
}
