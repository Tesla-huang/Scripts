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
die "Usage: perl $0 <in>\n" if @ARGV != 1;

my %eb = (0 => '0', 1 => '1', 2 => '2', 3 => '3', 4 => '4', 5 => '5', 6 => '6', 7 => '7', 8 => '8', 9 => '9', 10 => 'A', 11 => 'B',
		12 => 'C', 13 => 'D', 14 => 'E', 15 => 'F', 16 => 'G', 17 => 'H', 18 => 'I', 19 => 'J', 20 => 'K', 21 => 'L', 22 => 'M', 23 => 'N',
		24 => 'O', 25 => 'P', 26 => 'Q', 27 => 'R', 28 => 'S', 29 => 'T', 30 => 'U', 31 => 'V', 32 => 'W', 33 => 'X', 34 => 'Y', 35 => 'Z');

sub dec2eb
{
	my $dec = shift;
	my $eb = shift;
	my @new;
	while ($dec >= 36)
		{
			my $alt = $dec % 36;
			unshift @new, $$eb{$alt};
			$dec = int($dec/36);
			}
	unshift @new, $$eb{$dec};
	return join("", @new);
}

my ($in) = @ARGV;

my $alt = dec2eb ($in, \%eb);

print $alt."\n";
