#!/usr/bin/perl -w
use strict;
# Rich Lott 22 May 2006
#
my $happy = 1;
my ( $end, $startRE,$startflags, $endRE ) ;
my ( $start, $startOffset, $endOffset ) = ( 1, 0, 0 );

if 	  ( $#ARGV!=1 ) { $happy = 0 ; }
elsif ( $ARGV[1] ne '-' && ! -e $ARGV[1] ) 
	{ $happy = 0 ; print STDERR "File not found: $ARGV[1]"; }
else
{	#
	# check range is valid
	#
	# check if start of range is a regexp...
	if ( $ARGV[0] =~ m{^/} )
	{
		# need to find end of regexp - next / unless preceded by \!
		$ARGV[0] =~ m{
			^/			# starts with /
			(			# group pat 1
				.*?		# match as little as poss
				(?<!\\)	# backslash must not preceed...
			)
			/			# ...slash that closes pattern
			(i?)		# optional case insensitive flag captured as 2
			(			# capture as 3 offset from this regexp
				(?:[-+]\d+)? # which is optional
			)
			:			# end of "start" range specification
			(.*)		# rest of range (ie. end range) captured as 4
			$}x;
		if ( $2 ) 	{ $start = qr/$1/i ; }
		else		{ $start = qr/$1/ ;}

		$end = $4;
		$startRE = 1;
		$startOffset = $3;

		if ( $startOffset =~ m/^\+(\d+)$/  ) { $startOffset = 0 + ($1); }
		elsif ( $startOffset ne '' ) { $startOffset = 0 + $startOffset;}

	}
	elsif ( $ARGV[0] =~ m{(^-?\d*):(.*)$} )
	{
		# start range is a number
		$start=$1;
		$end=$2;
		$start=1 if ( $1 eq '' ) ;
	}
	else
	{
		# user error! not recognised range.
		$happy=0;
	}

	# ========= now check end of range ========= 
	if (  $end =~ m{
			^/			# starts with /
			(			# group pat 1
				.*		# match as much as poss
			)
			/			# ...slash that closes pattern
			(i?)		# optional case insensitive flag captured as 2
			(			# capture as 3 offset from this regexp
				(?:[-+]\d+)? # which is optional
			)
			$			# end 
			}x )
	{
		# end range is regexp
		$endRE = 1;
		if ( $2 ) 	{ $end = qr/$1/i ; }
		else		{ $end = qr/$1/ ;}

		$endOffset = $3;
		if ( $endOffset =~ m/^\+(\d+)$/  ) { $endOffset = 0 + ($1); }
		elsif ( $endOffset eq '' ) { $endOffset = 0; }
		else { $endOffset = 0 + $endOffset;}

	}
	elsif ( $end !~ m{^[-+]?\d*} )
	{
		# user error! not recognised range.
		$happy=0;
	}
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

	You can use a regexp of the form:
		/something/[i flag][offset]
	for the start or the end (or both). 
	The i flag (ie. just \"i\" alone, means case insensitive.
	The offset, must start with + or - followed immediately by an integer
	and is applied to the line number matching the regexp.
	
	So /rich/+1:/lott/i-2 would show the line FOLLOWING the match of /rich/
	up to two lines before the case insensitive match of /lott/

	And /rich/:+10 is equivalent to grep rich -A10

	The end pattern is searched from from the line AFTER the match of the start
	pattern (if given).

	Within regexps, \"/\" characters will need escaping with backslash.
    
    Examples
    range   returns..   
    1:2     first two lines (eg. head -n2 )
    3:      all lines starting at line 3
    1:-2    all lines except last two.
    -5:     last five lines
    7:+3    would give you three lines from 7
    -10:+2  would give you first two lines of the last ten (!)
	

	'/CREATE TABLE.*`schemes/:/^UNLOCK/' one2006-08-14.sql 
			or (if you know that drop table is the first) 
	'/DROP TABLE IF EXISTS .*`schemes/:/^UNLOCK/' one2006-08-14.sql 
			would fetch the sql for the schemes table from a big file
			of sql \n";
	exit;
}

#print " got range as \nstart : $start \nend: $end\n happy: $happy\n";

# read entire file
my @data = ();

if ( $ARGV[1] eq '-' )
{	@data = (<STDIN>); }
else
{
	open (FH, $ARGV[1]) or die( "$ARGV[1] must exist" );
	@data =(<FH>);
	close FH;
}

if ( $startRE )
{
	# grep through file for match to start.
	my $i =0 ;
	my $copy;
	foreach ( @data )
	{
		$copy=$_;
		chomp $copy;
		last if ( $copy =~ $start );
		$i++;
	}
	$start = 1+ $i;
	print STDERR "Info: start regexp matched line $start\n";
	$start += $startOffset;
	$start = 1 if ( $start<1 );
}
if ( $endRE )
{
	my $i;
	# grep through file for match to end.
	my $copy;
	foreach ( $start .. $#data )
	{
		$i=$_;
		$copy=$data[$i];
		chomp $copy;
		last if ( $copy =~ $end ) ;
	}
	$end = 1+$i;
	print STDERR "Info: end regexp matched line $end\n";
	$end += $endOffset;
	$end = $#data if ( $end>$#data );
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
