#!/usr/bin/perl -w
use strict;
sleep 1; # give the computer time to realise there's a card...

die ("Must be called for wlan0") if ($#ARGV != 0 || $ARGV[0] ne 'wlan0' )  ;

my $iface = $ARGV[0]; # always wlan0 !

my %known = qw/
			00:11:95:94:AA:A0 home
			00:E0:98:E3:94:C6 work /;

my @networks = ();
my %tmpnet = ();
# pipe output of scan to me
#open SCAN, "</home/rich/scaneg";
open FH, ">>/home/rich/wlanthing.log";

print FH `ps axf`, "\n\n";

print FH `date`, "\n\tScan full log:\n\t-------------\n";

my $fail=0;
open SCAN, "iwlist wlan0 scan 2>>/home/rich/wlanerr|" or $fail=1;
if ( $fail )
{ 	print FH "failed to open scan thingy.\n" ;
	
	print FH $_ while (<SCAN>);
	
	exit();
}

while (<SCAN>)
{
	print FH "\t\t$_";
	chomp;
	if ( /^\s+Cell \d+ - Address: (.*)$/ )
	{
		# start of new network
		# push any existing network onto @networks.
		push @networks, {%tmpnet} unless ( %tmpnet eq "0" );
#		print "new network. There are now " . @networks . " networks\n";

		# clear network hash
		%tmpnet = ('address',$1);
	}
	elsif ( /ESSID:"(.*)"/ ) { $tmpnet{'essid'}=$1 }
	elsif ( /Encryption key:(.*)/ ) { $tmpnet{'encryption'}=$1 }
	elsif ( /Quality(.*)/ ) { $tmpnet{'quality'}=$1 }
}
push @networks, {%tmpnet} unless ( %tmpnet eq "0" );
close SCAN;

my $net;
print FH "\n\tScan results:\n\t-------------\n";
#my $selected='rome';
my $selected='home';
my $netcount=1;
foreach $net ( @networks )
{
	print FH "\tNetwork ", $netcount++, "\n";
	print FH "\t\t$_ :" . $net->{$_} , "\n" foreach ( keys %{$net} ) ;
						#or: print "\t$_ :" . $$net{$_}," \n" ;
						#or: print "\t$_ :" . ${$net}{$_}," \n" ;
	# $net is a pointer to a hash
	if ( defined $known{$net->{'address'}} )
	{
		$selected = $known{$net->{'address'}};
		print FH "\t\t**Recognised address, using ", 
			$net->{'essid'}," ". 
			$known{$net->{'address'}}, "**\n";
		last;
	}
	else {print FH "\t\tUnknown network.\n" }
}
print $iface, '-', $selected, "\n";
print FH "\n\tOutput to ifup: ",$iface, '-', $selected, "\n\n";
close FH;

