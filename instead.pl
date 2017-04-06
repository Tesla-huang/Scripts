#!/usr/bin/perl
use strict;
use warnings;

die "Usage: perl $0 <in.fa> <r/n> <outprefix>\n" if @ARGV != 3;
my $fa = shift;
my $key = shift;
my $out = shift;

die "Please use another outprefix!!!\n" if $fa eq "$out.fa";

my %hash;
@{$hash{'W'}} = ('A','T');
@{$hash{'S'}} = ('G','C');
@{$hash{'K'}} = ('G','T');
@{$hash{'M'}} = ('A','C');
@{$hash{'R'}} = ('A','G');
@{$hash{'Y'}} = ('C','T');
@{$hash{'B'}} = ('T','C','G');
@{$hash{'D'}} = ('T','A','G');
@{$hash{'H'}} = ('T','C','A');
@{$hash{'V'}} = ('A','C','G');
@{$hash{'w'}} = ('a','t');
@{$hash{'s'}} = ('g','c');
@{$hash{'k'}} = ('g','t');
@{$hash{'m'}} = ('a','c');
@{$hash{'r'}} = ('a','g');
@{$hash{'y'}} = ('c','t');
@{$hash{'b'}} = ('t','c','g');
@{$hash{'d'}} = ('t','a','g');
@{$hash{'h'}} = ('t','c','a');
@{$hash{'v'}} = ('a','c','g');

open FA, $fa or die $!;
open OF, "> $out.fa" or die $!;
open VCF, "> $out.vcf" or die $!;
print VCF "#chr\tpos\torigin\tnow\n";

local $/ = "\n>";
while(<FA>)
{
	chomp;
	s/^>//;
	my @tmp = split /\n/, $_, 2;
	my @info = split /\s+/, $tmp[0], 2;
	$tmp[1] =~ s/\n//sg;
	my @na = split //, $tmp[1];
	delete $tmp[1];
	print OF ">$tmp[0]\n";
	my $i = 0;
	for my $a (@na)
	{
		$i ++;
		if ($a =~ /[AaTtCcGgNn]/)
		{
			print OF $a;
		}
		else
		{
			my $base = randelement(\@{$hash{$a}}, $key);
			print OF $base;
			print VCF "$info[0]\t$i\t$a\t$base\n";
		}
	}
	print OF "\n";
}
close FA;
close OF;
close VCF;

sub randelement
{
	my $array = shift;
	my $key = shift;
	if ($key =~ /^r/i)
	{
		return $$array[rand $array];
	}
	else
	{
		return "N";
	}
}
