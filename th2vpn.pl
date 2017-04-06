#!/usr/bin/perl -w

use strict;

while(1){
	my $status = `ping -w 4 -s 8 172.16.22.11 | grep 100%`;
	if ($status) {
		my $pid = `ps -A x | grep vpnclient64 | grep 61.144.43.67 | awk '{print \$1}'`;
		if ($pid) {
			chomp;
			my @pid = split /\n/, $pid;
			foreach my $id (@pid) {
				`kill -s 9 $id`;
			}
		}
#`nohup sh /home/linyifan/th2vpn.sh > /dev/null 2>&1 &`;
		`nohup vpnclient64 61.144.43.67 6443 sysu_ld_nscc bioinfoluoda321 > /dev/null 2>&1 &`;
	}
	sleep(15);
}
