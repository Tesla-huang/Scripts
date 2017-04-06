#!/usr/bin/perl
use strict;
use warnings;

my $fa = shift;

my %hash;
@{$hash{'A'}} = ('A');
@{$hash{'T'}} = ('T');
@{$hash{'C'}} = ('C');
@{$hash{'G'}} = ('G');
@{$hash{'N'}} = ('N');
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

open FA,$fa or die $!;
while(<FA>){
	if(/>/){
		print;
	}else{
		chomp;
		my @aa = split//,$_;
		for my $a(@aa){
			$a = uc($a);
			my $b = &randelement(@{$hash{$a}});
			print $b;
		}
		print "\n";
	}
}
close FA;

sub randelement{
	my (@array) = @_;
	return $array[rand @array];
}
