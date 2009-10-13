#!/usr/bin/perl -w
use strict;

my %details=();	
	print "No\ttime\ttable_chain\tIface in\tIface out\t" .
		"From\tTo\tProto\tid\tNotes\n";
my $no = 1;
while (<>)
{
	my ($time, $table, $inputIface, $outIface,
		$sourceIp, $spt,$destIp, $dpt,$proto, $id)
		= ('','','','','','','','','','');
								
	if ( m/^\w+\s+\d+\s+([\d:]+).*?kernel: (\w+)/ )
	{
		$time = $1;
		$table = $2;
	}

	$inputIface = $1 if m/IN=(\w*)/;

	$outIface = $1 if m/OUT=(\w*)/;
	
	$sourceIp = $1 if m/SRC=([\w.]*)/;

	$destIp = $1 if m/DST=([\w.]*)/;

	$proto = $1 if m/PROTO=(\w*)/;

	$spt = $1 if m/SPT=(\w*)/;

	$dpt = $1 if m/DPT=(\w*)/;

	$id = $1 if m/ID=(\w*)/;

	printf "%i\t%s\t%s\t%s\t%s\t%s:%s\t%s:%s\t%s\t%s\t\n",
		$no++, $time, $table, $inputIface, $outIface,
		$sourceIp, $spt,
		$destIp, $dpt,
		$proto, $id;
}
