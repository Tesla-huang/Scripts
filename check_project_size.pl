#! /usr/bin/perl

#	Author:	BaconKwan
#	Email:	pkguan@genedenovo.com
#	Version:	1.0
#	Create date:	
#	Usage:	

use utf8;
use strict;
use warnings;
use Net::SMTP_auth;
use File::Spec;
use Time::Local;

die "perl $0 <dir> <size[GB]> <outputlogprefix>\n" unless(@ARGV eq 3);

my $bin_path = File::Spec->rel2abs($0);
my ($vol, $dirs, $file) = File::Spec->splitpath($bin_path);


while(1){
	
	open MAIL, "$dirs/users.conf" || die $!;
	my %mail;
	while(<MAIL>){
		chomp;
		next if(/^#|^$/);
		my @line = split /\t/;
		$mail{$line[0]} = $line[1];
	}
	close MAIL;
	
	open SERVER, "$dirs/hostname.conf" || die $!;
	my %server;
	while(<SERVER>){
		chomp;
		next if(/^#|^$/);
		my @line = split /\t/;
		$server{$line[0]} = $line[1];
	}
	close SERVER;
	
	chomp(my $hostname = `hostname`);
	
	my %users;

	open INFO, "/etc/passwd" || die $!;
	foreach(<INFO>){
		chomp;
		my @line = split /:/;
		next unless(exists $mail{$line[0]});
		$users{$line[0]}{name} = $line[0];
	}
	close INFO;

	my $timestamp=time;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
	my $y = $year + 1900;
	my $m = $mon + 1;
	my $date = "$y-$m-$mday";
	`rm -rf $ARGV[2].$date.txt` if (-s "$ARGV[2].$date.txt");
	#foreach my $id (sort keys %users){
	#print "$id\n";
	#}
	
	my @list = `ls -l $ARGV[0]`;
	shift @list;
	
	foreach my $line (@list){
		chomp $line;
		my @tmp = split /\s+/, $line;
		push(@{$users{$tmp[2]}{dir}}, "$ARGV[0]/$tmp[8]");
	}
	
	foreach my $id (sort keys %users){
		next unless(exists $users{$id}{dir});
	#print "$id\n";
		my @send;
	

	open OUT, ">> $ARGV[2].$date.txt" or die $!;
		foreach my $dir (@{$users{$id}{dir}}){
	#print "$dir\n";
			my $line = `du --max-depth=0 $dir`;
			next unless ($line);
			chomp $line;
			my @line = split /\s+/, $line;
			$line[0] = $line[0] / 1024 / 1024;
			my $size = $line[0];
			$line[0] = sprintf("%.2fG", $line[0]);
			$line = join "\t", @line;
			my $today = time();

			#modify time
			my @mod_time = `ls --full-time $dir`;
			my $mod_time = `ls -d --full-time $dir`;
			push @mod_time, $mod_time;
			my $mod_day = 0;
			foreach my $i (@mod_time)
			{
				next unless ($i =~ /\d{4}-\d{2}-\d{2}/);
				chomp $i;
				my $tmp_time = (split /\s+/, $i)[5];
				my @tmp_time = split /-/, $tmp_time;
				my $tmp_day = timelocal(0,0,0,$tmp_time[2],$tmp_time[1]-1,$tmp_time[0]);
				$mod_day = $tmp_day if ($tmp_day > $mod_day);
			}
#			$mod_time = (split /\s+/, $mod_time)[5];
#			@mod_time = split /-/, $mod_time;
#			$mod_day = timelocal(0,0,0,$mod_time[2],$mod_time[1]-1,$mod_time[0]);
			my $mod_long = int(($today-$mod_day)/(60*60*24));

#			#access time
#			my @acc_time = `stat $dir | grep Access`;
#			my $acc_time = $acc_time[1];
#			chomp $acc_time;
#			$acc_time = (split /\s+/, $acc_time)[1];
#			@acc_time = split /-/, $acc_time;
#			my $acc_day = timelocal(0,0,0,$acc_time[2],$acc_time[1]-1,$acc_time[0]);
#			my $acc_long = int(($today-$acc_day)/(60*60*24));

			print OUT "$id\t$dir\t$line[0]\t$mod_long\n";
			$line .= "\t......Last modified time: $mod_long days ago";
			push(@send, $line) if($size >= $ARGV[1]);
		}
		next if(@send == 0);
		my $send_txt = join "\n", $id, @send;

#		&sendMail($send_txt, $mail{$id}, \%mail, \%server, $hostname);
		&sendMail($send_txt, $mail{linyifan}, \%mail, \%server, $hostname);

	#my $path = `pwd`;
	#chomp $path;
	#open TXT, ">", "$path/send.txt" || die $!;
	#print TXT "$send_txt\n";
	#close TXT;
	#`mail $id -s 'WARNING!!! clean your project size' < $path/send.txt`;
	#`rm $path/send.txt -rf`;
	}

	sleep(604800);
}

sub sendMail
{
	my ($content, $x, $mail, $server, $hostname) = @_;
	my $smtpHost = 'smtp.exmail.qq.com';
	my $smtpPort = '25';
	
	my $username = 'yflin@genedenovo.com';
	my $passowrd = 'Lyf19920425';
	
	my $subject = 'Notice!! clean your project in time.';

	my $message = "
Your projects on $$server{$hostname} are over $ARGV[1]G
We recommend you that project which is finished 3 months ago should be clean up!

Details:
$content

From monitoring program of $$server{$hostname}
";

	my $smtp = Net::SMTP_auth->new($smtpHost, Timeout => 30) or die "Error: connecting ${smtpHost} fail!\n";
	$smtp->auth('LOGIN', $username, $passowrd) or die("Error: authentication fail!\n");
	$smtp->mail($username);
	$smtp->to($x);
	$smtp->data();
	$smtp->datasend("To: $x\n"); # strict format
	$smtp->datasend("From: $username\n"); # strict format
	$smtp->datasend("Subject: $subject\n"); # strict format
	$smtp->datasend("Content-Type:text/plain;charset=UTF-8\n"); # strict format
	$smtp->datasend("Content-Trensfer-Encoding:7bit\n\n"); # strict format
	$smtp->datasend($message);
	$smtp->dataend();
	$smtp->quit();
}

#exec("for i in \`ls -l /Bio/Project/PROJECT/ | awk \'\$3 ~ /$ARGV[0]/\' | awk \'{print \$9}\'\`; do du --max-depth=0 /Bio/Project/PROJECT/\$i; done | awk \'\$1 > 10485760\' | mail -s \'WARNING!!! clean your project!!!\' $ARGV[0]");
