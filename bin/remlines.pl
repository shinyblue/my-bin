#!/usr/bin/perl -w
use strict;
die ("Usage: $0 needles haystack") unless $#ARGV==1;
my %lookup;

open N,$ARGV[0]; my @needles=<N>; close N;
open H,$ARGV[1]; my @hay=<H>;     close H;

@lookup{@needles} = ();
for (@hay) {print unless exists $lookup{$_}} 
