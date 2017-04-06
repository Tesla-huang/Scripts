#!/usr/bin/perl  -w

use strict;
use warnings;

die "Usage: perl $0  <BLAST>  <export>" unless ( @ARGV == 2 );

my ( $blast, $export ) = @ARGV;

open( BLAST,  $blast )     || die "$! \n";
open( EXPORT, ">$export" ) || die "$!\n";

print EXPORT qq{query\thsp_number\tquery_length\tsubject_length\tsubject\tbitScore\tscore\tevalue\tidentities\tquery_frame\tquery_from\tquery_to\thit_frame\thit_from\thit_to\tsubject_annot\tquery_string\thit_string\n};

local $/ = "\nQuery= ";

my $couter = 1;

while (<BLAST>) {

    chomp;

    my ($query)        = $_ =~ /^(\S+)/;
    my ($query_length) = $_ =~ /Length=(\d+)/;

    next if ( !/\n>/ );

    foreach my $hit ( split /\n>\s*/, $_ ) {

        next if ( $hit =~ /Sequences producing significant alignments/ );

        my ($subject, $subject_annot, $subject_length) = $hit =~ /^(\S+)\s+([\D\d]+)Length\s*=\s*(\d+)/;
        $subject_annot =~ s/\n//g;
        my $hsp_number       = 1;

        foreach my $hsp ( split /\n Score = /, $hit ) {

            next if ( $hsp !~ /Expect =/ );

            my ( $bit_score, $score ) = $hsp =~ /(\S+) bits\s+\((\S+)\)/;
            my ($identities) = $hsp =~ / Identities \= \S+ \((\S+%)\)/;
            my ($frame)      = ();
               ($hsp =~ / Frame \= (\S+)/) ? $frame = $1 : $frame = '/';

            my ($evalue)     = $hsp =~ / Expect\(*\d*\)* \= (\S+)/;

            my (@query_seq)  = $hsp =~ /Query  (.+)/g;
            my $query_string = join( "\t", @query_seq );
            
            my ( $query_from, $query_to ) = $query_string =~ /^(\d+).+?(\d+)$/;
            ( $query_from, $query_to ) = ( $query_to, $query_from ) if ( $query_from > $query_to );
            
            $query_string =~ s/\d+//g;
            $query_string =~ s/\s+//g;
            $query_string =~ s/\-//g;

            my @hit_seq = $hsp =~ /Sbjct  (.+)/g;
            my $hit_string = join( "\t", @hit_seq );
            my ( $hit_from, $hit_to ) = $hit_string =~ /^(\d+).+?(\d+)$/;
            
            $hit_string =~ s/\d+//g;
            $hit_string =~ s/\s+//g;
            $hit_string =~ s/\-//g;
            
            print EXPORT qq{$query\t$hsp_number\t$query_length\t$subject_length\t$subject\t$bit_score\t$score\t$evalue\t$identities\t$frame\t$query_from\t$query_to\t\/\t$hit_from\t$hit_to\t$subject_annot\t$query_string\t$hit_string\n};
            $hsp_number++;

        }

    }
    
    $couter++;

}

print $couter;

local $/ = "\n";
close BLAST;
close EXPORT;
exit;
