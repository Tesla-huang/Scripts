#!/usr/bin/env perl

#=head1 Name
#=head1 Introduction
#=head1 Author & Email
#=head1 Options
#=head1 Example
#=cut

use warnings;
use strict;
use Getopt::Long;
use threads;
use Thread::Semaphore;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;
use FindBin;

#my ($in, $out);
#GetOptions(
#		"in=s"    => \$in,
#		"out=s"   => \$out
#		);

#die `pod2text $0` unless ($in && $out);
die "Usage: perl $0 <in> <out>\n" if @ARGV != 2;

open IN, "gzip -dc $ARGV[0] |" or die $!;
open OUT, "> $ARGV[1]" or die $!;
while (<IN>)
{
	chomp;
	my @tmp = split /\t/, $_;
	my $pid = $tmp[3];
	$pid = "-" if ($pid eq "");
	my $tid = $tmp[0];
	$tid = "-" if ($tid eq "");
	my $go = $tmp[7];
	my $eid = $tmp[2];
	$eid = "-" if ($eid eq "");
	next if ($go eq "");
	$go =~ s/\s//g;
	my @go = split /;/, $go;
	$go = join("\t", @go);
	print OUT "$tid\t$eid\t$pid\t$go\n";
}
