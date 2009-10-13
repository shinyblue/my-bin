#!/usr/bin/perl -w
use strict;
use Data::Dumper;
die 'use: removelines.pl needles_to_remove haystack'  if ( $#ARGV != 1 ) ;

open( CUT, $ARGV[0] );
my %cuthash;
while ( <CUT> )
{
	chomp;
	$cuthash{ $_ } = 1; }
close CUT;

open( HAYSTACK, $ARGV[1] );
my @haystack = (<HAYSTACK>);
close HAYSTACK;

@haystack = grep { 
	chomp;
	! defined $cuthash{ $_ } ; 
} @haystack;
print join "\n",@haystack;

