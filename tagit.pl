#!/usr/bin/perl -w
use strict;

use Gtk2 -init;
use Glib qw|TRUE FALSE|;

my $window = Gtk2::Window->new ('toplevel');
$window->set_border_width(10);
$window->set_title("Tag files");
my $textentry = Gtk2::Entry->new;
my $tag = Gtk2::Button->new ('Tag');
my $box = Gtk2::HBox->new;

sub quit { Gtk2->main_quit; }

sub key_pressed {
    my ($widget,$event,$data) = @_;
    tagIt() if ($event->keyval==65293);
    return FALSE;
}

sub tagIt() {
	my $tagname=$textentry->get_text;
	return 0 if ( ! $tagname );
	my %files = ();
	if  ( open (FH, "/home/rich/tagsfiles/$tagname") )
	{
		while ( <FH> ) { chomp; $files{$_}=1 ;}
		close FH;
	}
	my $originalCount= scalar keys %files;
	print STDERR "original file contained $originalCount lines\n";
	$files{$_}=1 foreach ( @ARGV );
	if ($originalCount< scalar keys %files)
	{
#		print STDERR "re-writing $tagname file\n";
		open (FH, ">/home/rich/tagsfiles/$tagname");
		print FH join("\n",sort keys( %files)) . "\n";
		close FH;
	}
	quit();
}

$window->signal_connect(destroy =>\&quit);
$tag->signal_connect ( clicked => \&tagIt);
$textentry->signal_connect ( key_press_event => \&key_pressed);

$box->add ($textentry);
$box->add ($tag);
$window->add($box);
$window->show_all;
Gtk2->main;
0;
