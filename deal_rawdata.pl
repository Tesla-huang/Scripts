#!/usr/bin/perl -w

use strict;
use utf8;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;


die "Usage: perl $0 <directory> <depth> <read_type>\n" if @ARGV != 3;

my ($direct, $depth, $type) = @ARGV;

my $char = "/*"x$depth;
$direct = rel2abs($direct);
$direct .= $char.".gz";

open IN, "ls $direct | " or die $!;
my @tmp = <IN>;
@tmp = sort(@tmp);

my $file = 1;
$file = 2 if ($type =~ /pe/i);

my @order;
for (my $i = 0 ; $i < scalar(@tmp)/$file ; $i++){
    my $a = $i*$file;
    my $id = basename($tmp[$a]);
    if ($id =~ /_/)
    {
        $id  = (split /_/, $id)[0];
    }
    else
    {
        $id = (split /\./, $id)[0];
    }
    chomp($id);
    chomp($tmp[$a]);
    my $out = "$id : $tmp[$a]";
    if ($file == 2)
    {
        chomp($tmp[$a+1]);
        $out .= " $tmp[$a+1]";
    }
    $out .= "\n";
    print "$out";
    push @order, $id;
}
print "orders : ".join(" ", @order)."\n";
