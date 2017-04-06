#! /usr/bin/perl

use threads;
use Thread::Semaphore;
use strict;
use warnings;
use FileHandle;


our ($keep, $un, $f1, $f2, $out);
if (@ARGV eq 5) {
	($keep, $un, $f1, $f2, $out) = @ARGV;
}elsif (@ARGV eq 4) {
	($keep, $un, $f1, $out) = @ARGV;
	$f2 = "!xxx";
}else{
	die "perl $0 <keep[0],filter[1]> <unmapped.bam/fq.gz> <fq1> <fq2[optional]> <outprefix>\n";
}

my $flag = 0;

unless (-s "$f1") {
	$flag ++;
	print STDERR "is not exists $f1, please check the directory!!!\n";
}

unless ($f2 ne "!xxx" &&  -s "$f2") {
	$flag ++;
	print STDERR "is not exists $f2, please check the directory!!!\n";
}

die "Please check these error info, than rerun this script!!!\n" if ($flag > 0);

if ($un =~ /\.bam$/) {
	open IN, "samtools view $un |" or die $!;
}elsif ($un =~ /\.fq\.gz$/){
	open IN, "gzip -dc $un |" or die $!;
}else{
	open IN, "$un" or die $!;
}

my %read;
if ($un =~ /\.fq\.gz$/) {
	while (<IN>) {
		my $id = (split /\s+/, $_)[0];
		$id = (split /\//, $id)[0];
		<IN>;
		<IN>;
		<IN>;
		$read{$id} = 1;
	}
}else{
	while (<IN>) {
		next if (/^[@#]/);
		chomp;
		my $id = (split /\t/, $_)[0];
		$read{$id} = 1;
	}
}
close IN;

my $max_thread = 2;
my $semaphore = Thread::Semaphore->new( $max_thread );
my %fh_in;
my %fh_out;
my @file;

if ($f2 eq "!xxx") {
	push @file, $f1;
}else{
	push @file, $f1,$f2;
}

for (my $i = 0; $i < scalar @file; $i ++)
{
	$semaphore->down( );
	my $index = $i + 1;
	my $thread = threads->create( \&Catch, $file[$i], $index, $out, $keep);

	$thread->detach();
}

Wait4quit( );

sub Catch
{
	my $file = shift;
	my $index = shift;
	my $out = shift;
	my $keep = shift;
	open $fh_in{$index}, "gzip -dc $file |" or die $!;
	open $fh_out{$index}, "| gzip > $out\_$index.fq.gz" or die $!;
	while ($_ = $fh_in{$index}->getline) {
		my $line1 = $_;
		my $line2 = $fh_in{$index}->getline;
		my $line3 = $fh_in{$index}->getline;
		my $line4 = $fh_in{$index}->getline;
		my ($id) = $line1 =~ /@([^\/]+)/;
		if ($keep == 0) {
			if (!exists $read{$id}) {
				next;
			}else{
				my $text = $line1.$line2.$line3.$line4;
				$fh_out{$index}->print("$text");
			}
		}elsif ($keep == 1) {
			if (exists $read{$id}) {
				next;
			}else{
				my $text = $line1.$line2.$line3.$line4;
				$fh_out{$index}->print("$text");
			}
		}
	}
	$fh_in{$index}->close;
	$fh_out{$index}->close;
	$semaphore->up( );
}

sub Wait4quit 
{
	my $num = 0;
	while ( $num < $max_thread )
	{
		$semaphore->down( );
		$num ++;
	}
}
