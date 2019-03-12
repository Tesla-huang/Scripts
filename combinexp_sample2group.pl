#!/usr/bin/env perl

#=head1 Name
#=head1 Introduction
#=head1 Author & Email
#=head1 Options
#=head1 Example
#=cut

use utf8;
use warnings;
use strict;
use Getopt::Long;
use threads;
use Thread::Semaphore;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/rel2abs/;
use FindBin;
use YAML::Tiny;

die "Usage: perl $0 <rule.yml> <exp.matrix> <out>\n" if @ARGV != 3;

my ($rule, $exp, $out) = @ARGV;

open EXP, "$exp" or die $!;
my $head = <EXP>;
chomp($head);
my @head = split /\t/, $head;
shift(@head);
my %sample;
for my $offset (0 .. $#head)
{
    $sample{$head[$offset]} = $offset;
}

my $yml = YAML::Tiny->read($rule);
my %rule = %{$yml->[0]};
my %group;

for my $key (keys %rule)
{
    my @samples = split /\s+/, $rule{$key};
    my @offset;
    for my $sample (@samples)
    {
        push @offset, $sample{$sample};
    }
    @{$group{$key}} = @offset;
}

my %exp_group;

while(<EXP>)
{
    chomp;
    my @exp = split /\t/, $_;
    my $id = shift @exp;
    for my $key (keys %group)
    {
        my $sum = 0;
        for my $offset (@{$group{$key}})
        {
            $sum += $exp[$offset];
        }
        my $exp = sprintf("%.4f", $sum / scalar (@{$group{$key}}));
        $exp_group{$id}{$key} = $exp;
    }
}
close EXP;

my @group = (sort keys %group);
open OUT, "> $out" or die $!;
print OUT join("\t","Geneid",@group)."\n";
for my $id (sort keys %exp_group)
{
    print OUT "$id";
    for my $group (@group)
    {
        print OUT "\t$exp_group{$id}{$group}";
    }
    print OUT "\n";
}
close OUT;
