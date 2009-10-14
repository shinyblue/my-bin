#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;

# See http://perldoc.perl.org/Getopt/Long.html
# can set default options like this:
my %opts = ( 
		'help'    => 0,
		'openFile' => 0,
		);

GetOptions (\%opts, 'help', 'file!' );
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
# ...

# validate options and throw help back if the dear user has clearly misunderstood
# $opts{'help'}=1 if ( ... );
pod2usage(1) if ($opts{'help'});

# open folder on clipboard
#


my $file_manager = 'thunar';


# 1. get clipboard
$_ = `xclip -o`;
print "Source: $_\n";

# 2. convert to server, share, path
my ($server,$share,$pathWin,$pathNix) = ();
if ( m{^smb://([\w.]+?)/([\w.]+?)(/.*$|$)} ||
	 m{^//([\w.]+?)/([\w.]+?)(/.*$|$)} 	 ||
	 m{^\\\\([\w.]+?)\\([\w.]+?)(\\.*$|$)} ||
	 m{/smb/([\w.]+?)/([\w.]+?)(/.*$|$)} )
{
	$server = $1;
	$share = $2;
	$pathNix = $pathWin = $3;
	$server =~ s/(.*)/\l$1/;
	$share =~ s/(.*)/\l$1/;
	$pathNix =~ s{\\}{/}g if $pathNix =~ m{^\\};
	$pathWin =~ s{/}{\\}g if $pathWin =~ m{^/};
	print "Parsed output: \n\tServer: $server\n\tShare: $share\n\tPath: $pathNix\n";
}
else
{
	die('didn\'t recognise "$_"');
}

# 3. do we have that share mounted?
die("share $server/$share not mounted?") unless ( -d "/smb/$server/$share" );

# check it exists
my $path = "/smb/$server/$share/$pathNix";
die("file/folder does not exist") unless ( -e $path );

if (! $opts{'file'})
{
	# make sure we browse a folder
	$path =~ s{[^/]+$}{} unless ( -d $path );
}
exec($file_manager, $path);



__END__

=head1 NAME

this program does this...B<This program>

=head1 SYNOPSIS

program [options] files etc.

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

