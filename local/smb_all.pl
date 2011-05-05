#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# local username
my $user = $ENV{'USER'};

my %opts = ();
GetOptions (\%opts, 'private!', 'umount!' , 'unmount!' );

my @todo = split /\n/, <<EOF
#
# Maui
#
maui	rich	public
maui	web	public
maui	rsyncbackup	public
#
# Oahu
# Normal public, browsable shares
#
oahu	archive	public
oahu	design	public
oahu	hr	public
oahu	imdexdev	public
oahu	logos	public
oahu	org	public
oahu	photos	public
oahu	staff	public
#
# Oahu:
# Non-browseable shares
#
oahu	accounts	public
oahu	auto\$	public
oahu	db	public
oahu	dlists	public
oahu	format	public
oahu	homes	public
oahu	hr	public
oahu	imdexdev	public
oahu	mt	public
oahu 	netlogon      public
oahu	software	public
#oahu	backmin\$	public
#oahu	mailusers	public
#design	design	public
EOF
;

open FH, '</proc/mounts';
my $mounts = do { local $/; (<FH>); };
close FH;

# strip out comments
@todo = grep /^\s*[^#]/, @todo;

# if arguments given they are to match the first part of each @todo 
@todo = map { my $x = $_; grep /^\Q$x\E/i, @todo } @ARGV if (@ARGV > 0);
#	foreach my $arg (@ARGV) { push @tmp, grep /^\Q$arg\E/i ,@todo ; }
#	@todo = @tmp;
# print "New todo: " . scalar @todo . "\n";
# print "$_\n" foreach (@todo);
# exit 1;


if ($opts{'umount'} || $opts{'unmount'})
{
	do_umount($_) for (@todo);
}
else
{
	do_mount($_) for (@todo);
}

sub do_mount
{
	($_) = (@_);
	my ($server, $share, $public) = split /\s+/;
	my $dir = "/smb/$server/$share/";
	my $sharepath = "//$server/$share";
	if ($public eq 'private' && ! $opts{'private'}) 
	{
		printf STDERR "%-30snot public and -private not set, so skipping\n", $sharepath;
		return;
	}

	printf STDERR "%-30s", $sharepath;

	# already mounted?
	if ( $mounts =~ m{\Q$sharepath\E}i )
	{
		print STDERR "already mounted\n";
		return;
	}

	# create directory
	system('mkdir','-p',$dir) unless -e $dir;

	# do mount
	my @mountCmd = ();
	# nobrl is something about locking, required for openoffice to work!
	# nounix is something that stopped lots of permissions errors on a jaunty smbfs client.
	# rw is just rw.
	my $standardOpts = "nobrl,rw,nounix";
	$standardOpts = "rw,nobrl" if ( $sharepath =~ m/maui/i );
	if ($public eq 'public')
	{
		@mountCmd = ( 'mount.cifs', $sharepath, "/smb/$server/$share", '-o', 
				"$standardOpts,user,password=" ) ;
		$_ = system(@mountCmd);
	}
	else
	{
		@mountCmd = ('mount.cifs', $sharepath, "/smb/$server/$share", '-o', 
								"$standardOpts,user=$user/DOMAIN" );
		$_ = system(@mountCmd) ;
	}
	if ($_ != 0)
	{
		print STDERR "Failed.\n----Failed command:----\n@mountCmd\n\n" ;
	}
	else
	{
		print STDERR "Ok\n" ;
	}
}

sub do_umount
{
	($_) = (@_);
	my ($server, $share,$public) = split /\s+/;
	my $dir = "/smb/$server/$share";
	my $sharepath = "//$server/$share";

	printf STDERR "%-30s", $sharepath;

	# already mounted?
	if ( ! ($mounts =~ m{\Q$dir\E}i) )
	{
		print STDERR "not mounted\n";
#		print STDERR "$dir not in:\n$mounts";
		return;
	}

	# do umount
	$_ = system('umount.cifs', "/smb/$server/$share");

	if ($_ != 0)
	{
		print STDERR "Failed unmounting\n" ;
	}
	else
	{
		print STDERR "Unmounted ok\n" ;
	}
}
