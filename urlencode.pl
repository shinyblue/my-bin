#!/usr/bin/perl -w
use strict;
use URI::Escape;
print uri_escape($ARGV[0]);
#uri_unescape($val)
