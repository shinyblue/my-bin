#!/usr/bin/perl -w
use strict;

my $t=1;
while ($_ = shift @ARGV)
{
	my $f=join('',`ogginfo "$_"`);
	my $file = $_;
	my ($title,$art,$album)=('','','');
	$title = $1 if ( $f =~ m/title=(.*)$/mi );
	$art = $1 if ( $f =~ m/artist=(.*)$/mi );
	$album = $1 if ( $f =~ m/album=(.*)$/mi );
	system ("mv", $_, "$art - $album - $title.ogg", '-v');
}
