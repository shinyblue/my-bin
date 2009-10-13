#!/usr/bin/perl -w
use strict;
my @requiredTags=(@ARGV);

sub find_common
{	
	my %h =();
	my @common=();
	my @opts=@_;
	$h{ $_ } =1 foreach @{$opts[0]};
	foreach (@{$opts[1]})
	{
		push @common, $_ if exists $h{$_} ;
	}
	return @common;
}

my @result=();
# first, read first tag
$_ = shift @requiredTags;
	if (open (FH, "/home/rich/tagsfiles/$_"))
	{
		@result = (<FH>);
		close FH;
	}
while ( ($#requiredTags>-1) && ( $_ = shift @requiredTags ))
{
	# another tag required
	my @nextAnd = ();
	if (open (FH, "/home/rich/tagsfiles/$_"))
	{
		@nextAnd = (<FH>);
		close FH;
	}

	# now we have @result and @nextAnd;
	@result = find_common( \@result, \@nextAnd );
}
foreach (@result)
{
	chomp;
	my $or = $_;
	$_ = $2 if m{^(.*/)(.*)$};
	symlink $or, $_ ;
}
