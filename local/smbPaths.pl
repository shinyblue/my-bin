#!/usr/bin/perl -w
use strict;

open( LOG, ">>$ENV{HOME}/smbPaths.log" );
print LOG "--------------------------------------\n" . `date` . "\n";
print LOG "@ARGV \n";

my $usage = "Usage: $0 [-b|--browse] [-s|--smb] filepath\n".
			"       Converts smb filepaths ".
			"       --browse  select the file in a konqueror view\n".
			"       --smb     copy smb:// style path instead of \n" .
			"                 windows \\\\server\\share style one.\n";


# declare vars:
my ( $browse, $toWin ) = (0,1);

my @files = ();

while ($_ = shift @ARGV )
{
	if ( $_ eq '-b' 	|| $_ eq '--browse'	) { $browse = 1; }
	elsif ( $_ eq '-s' 	|| $_ eq '--smb'	) { $toWin=0; }
	elsif ( substr($_,0,1) eq '-' ) { die $usage; }
	else { push @files, $_; }
}
print LOG "files: " . (@files==1) . "\n";
die $usage unless (@files==1);
# foreach (@files) { die "file: $_ doesn't exist\n" unless -f $_ ; }

# split filename up
$_ = $files[0];

# if local, try to resolve symlinks
if ( m{^/[^/]} )
{
	# ensure ends with trailing / if a dir
	s{$}{/} if ( -d $_ && ! m{/$} );

	my ($p, $f) = m{^(.*/)(.*?)$};

	print "chdir: $p\n";
	$p=`cd "$p" ; pwd -P`;
	chomp $p;

	print "Path resolved to $p/$f\n" if ($_ ne "$p/$f" );
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
	die('didn\'t recognise ' .$_);
}

my $out='';
if ($toWin)
{
	$out = "\\\\$server\\$share$pathWin";
}
else
{
	$out = "smb://$server/$share$pathNix";
}

if ( $browse )
{
	# need to figure out local path
	my $local;
	if ( -d "/smb/$server/$share"  )
	{ $local=  "/smb/$server/$share$pathNix"; }
	else
	{ $local=  "smb://$server/$share$pathNix"; }
	system("konqueror --select \"$local\" &");
	$local =~ s{(^.*/).*$}{$1} ;
	print LOG "Browsing $local\n";
#	system("dolphin \"$local\" &");
#	system("kfmclient openURL \"$local\" &");
}

# now put on x clip board
print LOG "writing $out\n";
open FH, "|xclip -selection clip"; print FH $out; close FH;
close LOG;
