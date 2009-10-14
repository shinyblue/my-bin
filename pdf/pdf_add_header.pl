#!/usr/bin/perl -w
use strict;
use PDF::API2;
# http://cpan.uwinnipeg.ca/htdocs/PDF-API2/PDF/API2.html
# http://rick.measham.id.au/pdf-api2/
use Getopt::Long;
use File::Temp qw/ :POSIX /;
use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;


# validate inputs
my %opts = ();
GetOptions (\%opts, 'text=s', 'output=s', 'help!', 'overwrite!' );
my $file = $ARGV[0];
$opts{'help'} = 1 if (!$opts{'text'} || ! $file);
help_and_exit() if $opts{'help'};
die("$file does not exist") unless -r $file;

# set default output
$opts{'output'} = "_$file" unless ($opts{'output'});
$opts{'output'} = $file if ($opts{'overwrite'});

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
for (1 .. $pdf->pages)
{
	my $page = $pdf->openpage ($_);
	my $text = $page->text;
	my ($x,$y,$width,$height) = $page->get_cropbox();

	$text->font( $font{'Helvetica'}{'Bold'}, 10/pt );
	$text->fillcolor('black');
	$text->translate( $x +  $width/2, $y + $height - 7/mm );
	$text->text_center($opts{'text'});
}
# write to outfile then move to specified output
my $outfile = tmpnam();
$pdf->saveas ($outfile);
system('mv', $outfile, $opts{'output'});

sub help_and_exit
{
	print <<EOF
Usage: $0 inputfile.pdf -text 'Your text' -output out.pdf
Writes 'Your text' in the centre top of every page in the input PDF
Outputs to _inputfile.pdf unless -output or -overwrite specified

EOF
		;
	exit 0;
}
