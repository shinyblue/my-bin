#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;
use PDF::API2;
# http://cpan.uwinnipeg.ca/htdocs/PDF-API2/PDF/API2.html
# http://rick.measham.id.au/pdf-api2/
use File::Temp qw/ :POSIX /;
use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

# See http://perldoc.perl.org/Getopt/Long.html
# can set default options like this:
my %opts = ( 
		'header'  => '',
		'footer'  => '',
		'overwrite' => 0,
		'outfile' => '',
		'help'    => 0
		);

GetOptions (\%opts, 'header=s', 'footer=s','overwrite!','oufile=s', 'help' );
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

$opts{'help'} = 1 if (!$opts{'header'}  && ! $opts{'footer'} );
pod2usage(1) if ($opts{'help'} || $#ARGV!=0 );

my $file = $ARGV[0];
die("$file does not exist") unless -r $file;


# set default output
if ( ! $opts{outfile} )
{
	if ($opts{'overwrite'}) { $opts{'outfile'} = $file ; }
	else { $opts{'outfile'} = "_$file" ;}
}

# open input pdf
my $pdf = PDF::API2->open($file);
my %font = (
		Helvetica => {
			Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
			Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
			Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
			},
		Times => {
			Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
			Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
			Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
			},
		);

# loop through pages
my $pageCount = $pdf->pages;
for (1 .. $pageCount)
{
	my $pageNo = $_;
	my $page = $pdf->openpage ($pageNo);
	my $text = $page->text;
	my $write = '';
	my ($x,$y,$width,$height) = $page->get_cropbox();

	$text->font( $font{'Helvetica'}{'Bold'}, 10/pt );
	$text->fillcolor('black');

	# header
	if ($opts{'header'})
	{
		$write = $opts{'header'};
		$write =~ s/%n/$pageNo/g;
		$write =~ s/%N/$pageCount/g;

		$text->translate( $x +  $width/2, $y + $height - 7/mm );
		$text->text_center($write);
	}
	# footer
	if ($opts{'footer'})
	{
		$write = $opts{'footer'};
		$write =~ s/%n/$pageNo/g;
		$write =~ s/%N/$pageCount/g;

		$text->translate( $x +  $width/2, $y + 7/mm );
		$text->text_center($write);
	}
}
# write to outfile then move to specified output
my $outfile = tmpnam();
$pdf->saveas ($outfile);
system('mv', $outfile, $opts{'outfile'});


__END__

=head1 NAME

pdf_add_header.pl

=head1 SYNOPSIS

pdf_add_header.pl --header 'this is page %n of %N pages' --footer 'by me.' [opts] file.pdf

=head1 OPTIONS

=over 8

=item B<--header>

Set header text. %n for page No, %N for pages

=item B<--footer>

Set footer text. %n for page No, %N for pages

=item B<-yyyoptyyy>

help about yyyoptyyy option

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut

