#!/usr/bin/perl -w
use strict;

# takes list of ogg files, outputs a 
# numbered list of artist - title

my $t=1;
while (<>)
{
	chomp;
	my $f=join('',`ogginfo "$_"`);
	my $file = $_;
	my $title='';
	my $art='';
	$title = $1 if ( $f =~ m/title=(.*)$/mi );
	$art = $1 if ( $f =~ m/artist=(.*)$/mi );
	print $t++,' ', $art,' - ',$title, "\n";
}
