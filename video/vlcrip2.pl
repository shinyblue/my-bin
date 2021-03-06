#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;

# vlc dvd:///dev/dvd@20 --sout "#standard{access=file,mux=ps,dst=/home/us/Desktop/st.mpg}"         
# See http://perldoc.perl.org/Getopt/Long.html
# can set default options like this:
my %opts = ( 
		'track'   => 0,
		'help'    => 0
		);

GetOptions (\%opts, 'track=s@', 'help' );
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

