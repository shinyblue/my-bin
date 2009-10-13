#!/usr/bin/perl -w
use strict;
use POSIX ":sys_wait_h";

# Rich Lott
# Don't blame me if this wrecks anything
# basically just does sync, then calls eject.
#
# temporary, desparate effort to fix
# ubuntu bug 61946 / 70417

my $deviceMountPt='/dev/sda1/';

my $dcopTarget=$ARGV[0];

$deviceMountPt=`dcop $dcopTarget KommanderIf global ARGS`;
echo $deviceMountPt >/home/rich/Desktop/fred
chomp $deviceMountPt;

sub dirty
{
	open FH, '/proc/meminfo';
	my $filthy='';
	while ($filthy=<FH>)
	{ last if $filthy =~ m/^Dirty/; }
	close FH;
	chomp $filthy;
	$filthy =~ m/^\S+\s+(\d+)\s+(\w+)$/;
	$filthy = $1;
	$filthy *= 1024 if ($2 eq 'kB');
	$filthy *= 1024*1024 if ($2 eq 'MB');
	print "filthy $filthy\n";
	return $filthy;
}

my $maxDirty=dirty();
system "dcop $dcopTarget KommanderIf setMaximum 'pr' '$maxDirty'";

my $syncPid;
if (!defined($syncPid = fork())) {
    # fork returned undef, so failed
    die "Cannot fork: $!";
} elsif ($syncPid == 0) 
{
    # fork returned 0, so this branch is child
    # print "child working for 15s\n"; sleep 5; print "child ends\n";
    system("sync");
	exit;
    # exec("sync");
    # if exec fails, fall through to the next statement
    die "can't exec date: $!";
} else 
{
    # fork returned 0 nor undef
    # so this branch is parent

	# monitor $syncPid until it's done.
	system "dcop $dcopTarget KommanderIf setText 'statusLabel' 'Syncing...'";
	until (waitpid($syncPid,&WNOHANG)!=0)
	{
		my $filthy=dirty();
		if ( $maxDirty<$filthy ) 
		{
			$maxDirty=$filthy;
			system "dcop $dcopTarget KommanderIf setMaximum 'pr' '$maxDirty'";
		}
		system "dcop $dcopTarget KommanderIf setText 'pr' '" .  ($maxDirty - $filthy ). "'";
		select(undef, undef, undef, 0.25);
	}
	system "dcop $dcopTarget KommanderIf setText 'pr' '$maxDirty'";
	system "dcop $dcopTarget KommanderIf setText 'statusLabel' 'Ejecting$deviceMountPt...'";
	system "dcop $dcopTarget KommanderIf setVisible 'pr' 0";
	# ok, in sync, now eject
	if ( system("eject \"$deviceMountPt\"") == 0 )
	{
		system "dcop $dcopTarget KommanderIf setText 'statusLabel' '$deviceMountPt safe to remove!'";
	}
	else
	{
		system "dcop $dcopTarget KommanderIf setText 'statusLabel' 'FAILED to eject $deviceMountPt!'";
	}
}

