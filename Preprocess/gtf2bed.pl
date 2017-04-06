#!/usr/bin/perl
use Data::Dumper;

die "Usage: perl $0 <gff/gtf> <gene/trans> > outfile\n" if(@ARGV ne 2);

$in = shift @ARGV;
$type = shift @ARGV;
if($type eq 'gene')
{
	$type = "gene_id";
}elsif($type eq 'trans'){
	$type = "transcript_id";
}else{
	die "gene or trans\n";
}

open IN, ($in =~ /\.gz$/ ? "gunzip -c $in" : $in =~ /\.zip$/ ? "unzip -p $in" : "$in");
while (<IN>) {
	$gff = 2 if ($_ =~ /^##gff-version 2/ or $in =~ /gtf/);
	$gff = 3 if ($_ =~ /^##gff-version 3/ or $in =~ /gff/);
	next if /^#/ && $gff;

	s/\s+$//;
	# 0-chr 1-src 2-feat 3-beg 4-end 5-scor 6-dir 7-fram 8-attr
	my @f = split /\t/;
	if ($gff == 3) {
        # most ver 2's stick gene names in the id field
		($id) = $f[8]=~ /\bParent=([^.;]+)\.1/;
        # most ver 3's stick unquoted names in the name field
		($id) = $f[8]=~ /\bName=([^;]+)/ if !$id && $gff == 3;
	} else {
		($id) = $f[8]=~ /$type "([^;]+)"/;
	}

	next unless $id ;

	if ($f[2] =~ /exon/i) {
		die "no position at exon on line $." if ! $f[3];
        # gff3 puts :\d in exons sometimes
        $id =~ s/:\d+$// if $gff == 3;
		push @{$exons{$id}}, \@f;
		# save lowest start
		$trans{$id} = \@f if !$trans{$id};
	} elsif ($f[2] eq 'five_prime_UTR' or $f[2] eq 'start_codon') {
		#optional, output codon start/stop as "thick" region in bed
		$sc{$id}->[0] = $f[3];
	} elsif ($f[2] =~ /cds/i) {
		#optional, output codon start/stop as "thick" region in bed
		push @{$cds{$id}}, \@f;
		# save lowest start
		$cdx{$id} = \@f if !$cdx{$id};
	} elsif ($f[2] eq 'three_prime_UTR' or $f[2] eq 'stop_codon') {
		$sc{$id}->[1] = $f[4];
	}# elsif ($f[2] eq 'miRNA' ) {
	#	$trans{$id} = \@f if !$trans{$id};
	#	push @{$exons{$id}}, \@f;
	#}
}

for $id ( 
	# sort by chr then pos
	sort {
		$trans{$a}->[0] eq $trans{$b}->[0] ? 
		$trans{$a}->[3] <=> $trans{$b}->[3] : 
		$trans{$a}->[0] cmp $trans{$b}->[0]
	} (keys(%trans)) ) {
		my ($chr, undef, undef, undef, undef, undef, $dir, undef, $attr, undef, $cds, $cde) = @{$trans{$id}};
        my ($cds, $cde);
        ($cds, $cde) = @{$sc{$id}} if $sc{$id};

		# sort by pos
		my @ex = sort {
			$a->[3] <=> $b->[3]
		} @{$exons{$id}};

		my $beg = $ex[0][3];
		my $end = $ex[-1][4];
		
		if ($dir eq '-') {
			# swap
			$tmp=$cds;
			$cds=$cde;
			$cde=$tmp;
			$cds -= 2 if $cds;
			$cde += 2 if $cde;
		}

		# not specified, just use exons
		$cds = $beg if !$cds;
		$cde = $end if !$cde;

		# adjust start for bed
		--$beg; --$cds;
	
		my $exn = @ex;												# exon count
		my $exst = join ",", map {$_->[3]-$beg-1} @ex;				# exon start
		my $exsz = join ",", map {$_->[4]-$_->[3]+1} @ex;			# exon size

		# added an extra comma to make it look exactly like ucsc's beds
		print "$chr\t$beg\t$end\t$id\t0\t$dir\t$cds\t$cde\t0\t$exn\t$exsz,\t$exst,\n";
}


close IN;
