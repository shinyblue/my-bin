#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use URI::Escape;

my $use_notify = system('which', 'notify-send') == 0;
# @_ = ('rich lott','hello');
# my @cmd = map( uri_escape($_), ( 'notify-send', @_));
# print @_, "\n", @cmd, "\n";
# exit;

open( LOG, ">>$ENV{HOME}/smbPaths.log" );
print LOG "--------------------------------------\n" . `date` . "\n";
print LOG "@ARGV \n";

my %opts = ( 
		'browse' => 0,
		'smb'    => 0,
		);
GetOptions (\%opts, 'browse!', 'smb!', 'help!' );

print LOG "$_: ", $opts{$_}, "\n" foreach keys %opts;

my $usage = "Usage: $0 [-b|--browse] [-s|--smb] filepath\n".
			"       Converts smb filepaths \n".
			"       --browse  select the file in a konqueror view\n".
			"       --smb     copy smb:// style path instead of \n" .
			"                 windows \\\\server\\share style one.\n";

sub openInFileBrowser { # {{{
	# need to figure out local path
	my ($server, $share, $pathNix) = @_;
	$server =~ s/(.*)/\L$1/;
	$share =~ s/(.*)/\L$1/;
	my ($filepath, $dirname) = ();
	if ( -d "/smb/$server/$share"  )
	{ 
		$filepath = "/smb/$server/$share$pathNix"; 
		$dirname = $filepath;
		# if not a directory
		$dirname =~ s{(^.*/).*$}{$1} unless ( -d $filepath );
	}
	else
	{ $filepath = $dirname =  "smb://$server/$share$pathNix"; }

	# konqueror is good, it can open dirs and select files
	# system("konqueror --select \"$filepath\" &");
	# system("kfmclient openURL \"$filepath\" &");
	# system("dolphin \"$filepath\" &");
	print LOG "Browsing $dirname\n";

	my $pid = fork();
	if (not defined $pid) {
		print STDERR "Fork failed\n";
		exit;
	} elsif ($pid == 0) {
		# child process - run the command and exit.
		my @cmd = ('nautilus', $dirname);
		# indirect object syntax means no shell is invoked, so no escaping required.
		exec {$cmd[0]} @cmd;
	}
} # }}}
sub notify { # {{{
	my (@params) = (@_);
	if (!$use_notify)
	{
		print LOG "(no notify-send): ", @params;
		return;
	}
	# the notify command requires backslashes to be escaped
	map { s/\\/\\\\/g; $_; } @params;
	my @cmd = ( 'notify-send', @params);
	system {$cmd[0]} @cmd;
} # }}}

my @files = @ARGV;
if (@files==0)
{
	print LOG "No filename given, trying clipboard...\n";
	$files[0] = `xclip -o -selection clipboard`;
	print LOG "got: @files\n";
	chomp $files[0];
}
print LOG "files: " . (@files==1) . "\n";
die $usage unless (@files==1);
print LOG "ok\n";

# nautilus puts %20 for spaces etc.
$_ = uri_unescape($files[0]);

# split filename up into server, share, path

# if local, try to resolve symlinks
if ( m{^/[^/]} )
{
	# ensure ends with trailing / if a dir
	s{$}{/} if ( -d $_ && ! m{/$} );

	my ($p, $f) = m{^(.*/)(.*?)$};

	print LOG "chdir: $p\n";
	$p=`cd "$p" ; pwd -P`;
	chomp $p;

	print LOG "Path resolved to $p/$f\n" if ($_ ne "$p/$f" );
	$_="$p/$f";
}
my ($server,$share,$pathWin,$pathNix) = ();
if ( m{^smb://([\w.]+?)/([\w.]+?)(/.*$|$)} ||
	 m{^//([\w.]+?)/([\w.]+?)(/.*$|$)} 	 ||
	 m{^/?smb/([\w.]+?)/([\w.]+?)(/.*$|$)} ||
	 m{^\\\\([\w.]+?)\\([\w.]+?)(\\.*$|$)} )
{
	$server = $1;
	$share = $2;
	$pathNix = $pathWin = $3;
	$pathNix =~ s{\\}{/}g if $pathNix =~ m{^\\};
	$pathWin =~ s{/}{\\}g if $pathWin =~ m{^/};
}
else
{
	print LOG "FAIL: didn't recognise $_\n";
	notify("FAIL: did not recognise", $_);
	die('didn\'t recognise ' .$_);
}

my $out='';
if ($opts{smb})
{
	$out = "smb://$server/$share$pathNix";
}
else
{
	$out = "\\\\$server\\$share$pathWin";
}

openInFileBrowser( $server, $share, $pathNix ) if ( $opts{browse} );

# now put on x clip board
print LOG "writing path to selection: $out\n";
open FH, "|xclip -selection clipboard -i"; print FH $out; close FH;
notify("Copied " . ( $opts{smb} ? '*nix' : 'windows' ) . " filepath:", $out);
close LOG;
