#!perl
use strict;
use warnings;
use GO::OntologyProvider::OboParser;

die "perl $0 <.P|F|C>\n" if(@ARGV != 1);

my $obo_file = "/Bio/Database/Database/GO_April2015/20150407_go-basic.obo";

my ($pre, $t) = $ARGV[0] =~ /^(\S+)\.(\S)$/;
my $ol = GO::OntologyProvider::OboParser->new(ontologyFile => $obo_file, aspect => $t);

my %go;
open PFC, $ARGV[0] or die $!;
while(<PFC>)
{
	chomp;
	my @tmp = split;
	my $node = $ol->nodeFromId($tmp[4]);
	next unless($node && $node->isValid);
	$go{$node->goid."\t$tmp[1]\t".$node->term} ++;
	foreach my $path($node->pathsToRoot)
	{
		my $n = 0;
		foreach my $i(@{$path})
		{
			next if(++$n <= 2);
			$go{$i->goid."\t$tmp[1]\t".$i->term} ++;
		}
	}
}

open OUT, "> $pre.$t.tmp" or die $!;
#print OUT "GOID\tGeneID\tGOterm\n";
foreach(keys %go)
{
	print OUT "$_\n";
}
