#!/usr/bin/perl -w
use strict;
die ("Must be called for wlan0") if ($#ARGV != 0 || $ARGV[0] ne 'wlan0' )  ;
my $SND_TRY="/usr/share/sounds/KDE_Beep_Connect.ogg";
my $SND_SUCCESS="/usr/share/sounds/KDE_TypeWriter_Bell.ogg";
my $SND_FAIL="/usr/share/sounds/KDE_Error_3.ogg";

my $iface = $ARGV[0]; # always wlan0 !

# pipe output of scan to me
#open SCAN, "</home/rich/scaneg";
open FH, ">>/home/rich/wlanthing.log";

sub play
{
	system("/usr/bin/play -v 0.3 $_[0] >/dev/null 2>&1 &");
}

sub tryscan # {{{
{

	my %known = qw/
				00:11:95:94:AA:A0 home
				00:17:9A:D4:12:88 ruth
				00:16:E3:F6:E4:12 mumanddad
				00:18:4D:21:B1:E3 ca_angel
				00:1B:2F:78:B2:34 work /;

	my @networks = ();
	my %tmpnet = ();
	#print FH `ps axf`, "\n\n";
	print FH `date`, "\n\tScan full log:\n\t-------------\n";

	my $fail=0;
	open SCAN, "iwlist wlan0 scan 2>>/home/rich/wlanerr|" or $fail=1;
	if ( $fail )
	{ 	
		print FH "failed to open scan thingy.\n" ;
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
			# print FH "new network. There are now " . @networks . " networks\n";

			# clear network hash
			%tmpnet = ('address',$1);
		}
		elsif ( /ESSID:"(.*)"/ ) { $tmpnet{'essid'}=$1 }
		elsif ( /Encryption key:(.*)/ ) { $tmpnet{'encryption'}=$1 }
		elsif ( /Quality:(.*)/ ) { $tmpnet{'quality'}=$1 }
	}
	push @networks, {%tmpnet} unless ( %tmpnet eq "0" );
	close SCAN;

	my $net;
	print FH "\n\tScan results:\n\t-------------\n";
	my $selected='rome';
	my $netcount=1;
	my ($bestNet,$bestNetQuality,$dhcp) = ( '', 0,1 );
	foreach $net ( @networks )
	{
		#	print FH "\tNetwork ", $netcount++, "\n";
		#	print FH "\t\t$_ :" . $net->{$_} , "\n" foreach ( keys %{$net} ) ;
							#or: print "\t$_ :" . $$net{$_}," \n" ;
							#or: print "\t$_ :" . ${$net}{$_}," \n" ;
		# $net is a pointer to a hash
		if ( defined $known{$net->{'address'}} )
		{
			$selected = $known{$net->{'address'}};
				print FH "\t\t**Recognised address, using ", 
				$net->{'essid'}," ". 
				$known{$net->{'address'}}, "**\n";
			$dhcp = 0; # this is *not* 'rome'
			last;
		}
		else 
		{  
			my $q = 0;
			$q = $1 if $net->{'quality'} =~ m/^(\d+)/;
			print FH "\t\tUnknown network: $net->{'essid'}, quality $q\n" ;
			if ( ($q > $bestNetQuality) && ($net->{'encryption'} eq 'off'))
			{
				print FH "\t\tBest unsecured network so far.\n";
				$bestNetQuality = $q;
				$bestNet = $net->{'essid'};
			}
		}
	}
	return $selected if ( ! $dhcp );
	
	# for dhcp, roaming, write essid into /etc/wlanthing_essid
	open BN, '>/etc/wlanthing_essid';
	print BN $bestNet;
	close BN;
	print FH "\t\tsuggesting 'rome' - open network $bestNet, quality $bestNetQuality\n";
	return 'rome';
} # }}}

my $selected;
for my $i (1 .. 5)
{
	print FH "try $i\n";
	play $SND_TRY;
	$selected = tryscan();
	if ( $selected ne 'rome' ) 
	{
		print $iface, '-', $selected, "\n";
		play $SND_SUCCESS;
		exit;
	}
}
play $SND_FAIL;
print $iface,'-',$selected,"\n";
print FH "\n\tOutput to ifup: ",$iface, '-', $selected, "\n\n";
close FH;

