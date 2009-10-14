#!/usr/bin/perl -w
use strict;
use Data::Dumper;

# sudo perl -MCPAN -e 'install Image::ExifTool'
# Image::ExifTool::ImageInfo('filename')
# returns ref to hash like:
# {
#          'WhiteBalance (1)' => 'Auto',
#          'ThumbnailOffset' => '1410',
#          'Model' => 'FinePix S6500fd',
#          'FlashpixVersion' => '0100',
#          'ShutterSpeed' => '1/5',
#          'ResolutionUnit' => 'inches',
#          'FocalLength35efl' => '6.2mm (35mm equivalent: 27.9mm)',
#          'LightSource' => 'Unknown (0)',
#          'MeteringMode' => 'Multi-segment',
#          'FlashStrength' => 0,
#          'InteropVersion' => '0100',
#          'BrightnessValue' => '-2.79',
#          'MIMEType' => 'image/jpeg',
#          'FileType' => 'JPEG',
#          'ResolutionUnit (1)' => 'inches',
#          'ExifToolVersion' => '6.76',
#          'DynamicRange' => 'Standard',
#          'LightValue' => '2.1',
#          'Directory' => '.',
#          'ISO' => 800,
#          'Version' => '0130',
#          'ImageHeight' => 1536,
#          'FujiFlashMode' => 'Off',
#          'Make' => 'FUJIFILM',
#          'DateTimeOriginal' => '2007:03:30 07:04:38',
#          'InteropIndex' => 'R98 - DCF basic file (sRGB)',
#          'SlowSync' => 'Off',
#          'ApertureValue' => '2.8',
#          'ExifImageWidth' => 2048,
#          'SensingMethod' => 'One-chip color area',
#          'ScaleFactor35efl' => '4.5',
#          'ExposureProgram' => 'Landscape',
#          'InternalSerialNumber' => 'FC GAE00346 592D31343134 2006:11:14 85F330122021',
#          'Quality' => 'NORMAL ',
#          'ComponentsConfiguration' => 'YCbCr',
#          'FocusMode' => 'Auto',
#          'Flash' => 'Off',
#          'YCbCrPositioning (1)' => 'Co-sited',
#          'ShutterSpeedValue' => '1/5',
#          'ModifyDate' => '2007:03:30 07:04:38',
#          'Orientation' => 'Horizontal (normal)',
#          'FocalLength' => '6.2mm',
#          'YCbCrPositioning' => 'Co-sited',
#          'WhiteBalance' => 'Auto',
#          'ExifVersion' => '0220',
#          'ImageSize' => '2048x1536',
#          'ThumbnailImage' => ####### binary blob goes here but I removed it ########,
#          'XResolution (1)' => '72',
#          'CompressedBitsPerPixel' => '2',
#          'ImageWidth' => 2048,
#          'ExposureTime' => '1/5',
#          'HyperfocalDistance' => '2.06 m',
#          'Sharpness (1)' => 'Normal',
#          'CircleOfConfusion' => '0.007 mm',
#          'FileSource' => 'Digital Camera',
#          'Compression' => 'JPEG (old-style)',
#          'ThumbnailLength' => 8384,
#          'Orientation (1)' => 'Horizontal (normal)',
#          'Copyright' => '    ',
#          'ExposureMode' => 'Auto',
#          'FocalPlaneYResolution' => '2662',
#          'FileName' => '001.jpg',
#          'XResolution' => '72',
#          'ExposureWarning' => 'Good',
#          'CreateDate' => '2007:03:30 07:04:38',
#          'PictureMode' => 'Landscape',
#          'AutoBracketing' => 'Off',
#          'FileModifyDate' => '2007:04:03 10:10:42',
#          'SubjectDistanceRange' => 'Unknown (0)',
#          'SceneType' => 'Directly photographed',
#          'ColorSpace' => 'sRGB',
#          'ExposureCompensation' => '0',
#          'BlurWarning' => 'Blur Warning',
#          'SequenceNumber' => 0,
#          'Macro' => 'Off',
#          'Sharpness' => 'Normal',
#          'CustomRendered' => 'Normal',
#          'SceneCaptureType' => 'Landscape',
#          'FileSize' => '761 kB',
#          'FocusWarning' => 'Good',
#          'YResolution' => '72',
#          'Aperture' => '2.8',
#          'FocalPlaneXResolution' => '2662',
#          'FocusPixel' => '1024 768',
#          'YResolution (1)' => '72',
#          'ExifImageLength' => 1536,
#          'FocalPlaneResolutionUnit' => 'cm',
#          'MaxApertureValue' => '2.8',
#          'FNumber' => '2.8',
#          'Software' => 'Digital Camera FinePix S6500fd Ver1.00'
#        };
use Image::ExifTool qw(:Public);

while (my $file = shift(@ARGV))
{
	my $exif=Image::ExifTool::ImageInfo($file);
	if  (! defined $exif || defined $$exif{'Error'} )
	{
		print STDERR "$$exif{'Error'}: $file - skipping it.\n";
		next;
	}
	unless ( $$exif{'MIMEType'} eq 'image/jpeg' )
	{
		print STDERR "$file is $$exif{'MIMEType'} not image/jpeg - skipping it.\n";
		next;
	}
	my $ss = $$exif{'ShutterSpeed'};
	$ss =~ s|1/2 |half |;
	$ss =~ s|1/3 |3rd|;
	$ss =~ s|0.2 |5th|;
	$ss =~ s|1/(\d+)|$1th|;
	$ss =~ s| |_|g;
	my $fno = $$exif{'ApertureValue'};
	my $iso = $$exif{'ISO'};
	$file =~ m/^(.*)(\..*)$/;
	my $newFilename = "$1_iso$iso,f$fno,speed${ss}_s$2";
	if ( -e $newFilename )
	{
		print STDERR "Cannot rename $file to $newFilename, as already exists\n";
	}
	else
	{
		print "mv $file $newFilename\n";
		system('mv',$file,$newFilename);
	}
}

