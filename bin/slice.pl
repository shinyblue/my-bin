#!/usr/bin/perl -w
use strict;
# Rich Lott 22 May 2006
#

my $happy = 1;
my ( $start, $end ) ;

if 	  ( $#ARGV!=1 ) { $happy = 0 ; }
elsif ( $ARGV[1] ne '-' && ! -e $ARGV[1] ) 
	{ $happy = 0 ; print STDERR "File not found: $ARGV[1]"; }
else
{	#
	# check range is valid
	#
	( $start, $end ) = split(':', $ARGV[0] );
	$happy=0 unless ( $start =~ m/^-?\d+$/ && $end =~ m/^([-+]?\d+)|$/ );
}

if ( ! $happy )
{
    print STDERR  "usage: $0 <start>:[<end>] <file>
    <file> may be - for stdin
    <start> is the line number to start from, eg. 1 for first line.
    <end> is the line number to end at. 
          May be omitted.
          May be +n which will give n lines.
    
    Negative numbers are counted backwards from the end of the file
    
    Examples
    range   returns..   
    1:2     first two lines (eg. head -n2 )
    3:      all lines starting at line 3
    1:-2    all lines except last two.
    -5:     last five lines
    7:+3    would give you three lines from 7
    -10:+2  would give you first two lines of the last ten (!)
    \n";
	exit;
}

# read file
my @data = ();

if ( $ARGV[1] eq '-' )
{	@data = (<STDIN>); }
else
{
	open (FH, $ARGV[1]) or die( "$ARGV[1] must exist" );
	@data =(<FH>);
	close FH;
}


if ( $start > 0 ) 	{ $start-- ; }
else 				{ $start += $#data + 1; } 

$start = 0 if ( $start<0 );

if    ( $end eq '' )		{ $end = $#data + 1; }
elsif ( $end =~ m/^\+/ )	{ $end = $start + substr( $end, 1 ) ; }

if ( $end > 0 ) 	{ $end-- ; }
else 				{ $end += $#data; } 

$end = ( $#data  ) if ( $end > ( $#data  ) );

print @data[ $start .. $end ] unless ( $end < $start );
