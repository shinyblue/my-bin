#!/usr/bin/perl -w
#
# Functions:
#
# filepaths can be provided as argument, otherwise read from xclip
#
# 1. take a windows filepath \\server\share\path[\file.xxx]
#    and open a nautilus view on it.
#    (should also work on local filepaths)
#    
#    - expects mounts at /server/share/
#    - will try mount if dir empty
#    - will try smb://server/share as fallback
#
# 2. take a *nix filepath, /server/share/...
#                          smb://server/share/...
#                          //server/share/... (?)
#    and put the windows path on the clipboard.
#
# -smb means copy smb:// not \\server\share
#
use strict;
use Getopt::Long;
use Pod::Usage;
use URI::Escape;

my $debugging=1;

# find out what we're doing {{{
# See http://perldoc.perl.org/Getopt/Long.html
# can set default options like this:
my %opts = ( 
		'help' => 0,
		'open' => 0,
		'copy' => 0,
		'smb'  => 0,
		);

GetOptions (\%opts, 'help', 'open!','copy!','smb!' ); # {{{
# typed things
# --------------------------------------------
# string			: filename=s 
# repeated string	: filenames=s@
# bool				: help!  or just 	help
# 					  Nb. --help will set 1, --no-help will set 0
# integer			: count=i
# perl integer		: qty=o
# 					  e.g. --qty=0x20 for 32
# real number		: price=f
#
# typed things: optional values
# --------------------------------------------
# string			: filename:s
# }}}

# validate options and throw help back if the dear user has clearly misunderstood
$opts{'help'}=1 if ( ! $opts{copy} && ! $opts{open} );
output("Task: copy file path") if ($opts{copy});
output("Task: open folder") if ($opts{open});

my @files = @ARGV;
if (@files==0)
{
	output("No filename given, trying clipboard...\n");
	$files[0] = `xclip -o -selection clipboard`;
	output("got: @files\n");
	chomp $files[0];
}
output("Files count: " . (@files==1) . "\n");
$opts{help}=1 unless (@files==1);
pod2usage(1) if ($opts{'help'});

# }}}

# split path into bits {{{
output("Got what we need to run...\n");
# config
my $use_notify = system('which', 'notify-send') == 0;
my $file_manager = 'nautilus';
my $serversList = 'oahu|maui';

# nautilus puts %20 for spaces etc.
$_ = uri_unescape($files[0]);
# clean it up: trim 
s/^\s*(.*)\s+$/$1/;
# clean it up: replace line breaks with single spaces 
s/[ \t][\r\n]+[ \t]+/ /g;
output("Source (cleaned): $_\n");

# split filename up into server, share, path
#
# if local, try to resolve symlinks
if ( m{^/[^/]} )
{
	# ensure ends with trailing / if a dir
	s{$}{/} if ( -d $_ && ! m{/$} );

	my ($p, $f) = m{^(.*/)(.*?)$};

	output("chdir: $p\n");
	$p=`cd "$p" ; pwd -P`;
	chomp $p;

	output("Path resolved to $p/$f\n") if ($_ ne "$p/$f" );
	$_="$p/$f";
}

my ($server,$share,$pathWin,$pathNix) = ();
if (        m{^smb://([\w.]+?)/([\w.]+?)(/.*$|$)} ||
	            m{^//([\w.]+?)/([\w.]+?)(/.*$|$)} ||
	        m{^/($serversList)/([\w.]+?)(/.*$|$)} ||
	 m{^file:///($serversList)/([\w.]+?)(/.*$|$)} ||
	        m{^\\\\([\w.]+?)\\([\w.]+?)(\\.*$|$)} )
{
	$server = $1;
	$share = $2;
	
	$pathNix = $3;
	if ($pathNix)
	{
		$pathNix =~ s{^.}{};
			
		$pathWin = $pathNix;
		$pathNix =~ s{\\}{/}g if $pathNix =~ m{^\\};
		$pathWin =~ s{/}{\\}g if $pathWin =~ m{^/};
	}
}
else
{
	output("FAIL: didn't recognise $_\n");
	mydie('Didn\'t recognise ' .$_);
}
# }}}

# main doing bit
open_folder() if $opts{open};
copy_path() if $opts{copy};


sub output { # {{{
	my ($msg) = @_;
	print $msg;
	system('logger','-t','openFolder',$msg) if ($debugging);
} # }}}
sub mydie { # {{{
	my ($msg) = @_;
	output( $msg );
	notify("-i","error","Could not open filepath", $msg );
	exit 1;
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
sub copy_path { # {{{
	my $out = "\\\\$server\\$share" 
		. ($opts{smb} ? '/' : '\\') 
		. "$pathWin";
	$out = "smb://$server/$share/$pathWin" if ($opts{smb});
	open FH, "|xclip -selection clipboard -i"; print FH $out; close FH;
	notify("Copied " . ( $opts{smb} ? '*nix' : 'windows' ) . " filepath:", $out);
} # }}}
sub open_folder { # {{{
	# need to figure out local path
	#my ($server, $share, $pathNix) = @_;
	# always lower case server, share names
	$server =~ s/(.*)/\L$1/;
	$share =~ s/(.*)/\L$1/;

	my ($filepath, $dirname) = ();

	if ( -d "/$server/$share"  )
	{
		$filepath = "/$server/$share/$pathNix"; 
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
	output("Browsing $dirname\n");

	my $pid = fork();
	if (not defined $pid) {
		mydie("Fork failed\n");
	} elsif ($pid == 0) {
		# child process - run the command and exit.
		my @cmd = ('nautilus', $dirname);
		# indirect object syntax means no shell is invoked, so no escaping required.
		exec {$cmd[0]} @cmd;
	}
} # }}}


__END__

=head1 NAME

openFolder opens a smb folder on the clipboard.

=head1 SYNOPSIS

the path must be /server/share/...

Options:
-help brief help message

=head1 OPTIONS

=over 8

=item B<-xxxoptxxx>

help about xxxoptxxx option

=item B<-yyyoptyyy>

help about yyyoptyyy option

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut

