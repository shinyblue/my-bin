#!/usr/bin/perl -w
use strict;
# use Data::Dumper;
use Math::BigInt lib => 'GMP'; # http://perldoc.perl.org/Math/BigInt.html

my $slow;
shift @ARGV if ( $slow = $ARGV[0] eq '-s' );
my $lookFor = $ARGV[0];

# read values
my (@valueLines, @values);
while (<STDIN>) { chomp;  push @valueLines, $_; }

# numerical sort
@valueLines = sort { 
	my ($an, $dummy, $bn);
	($an, $dummy) = split /\s+/, $a;
	($bn, $dummy) = split /\s+/, $b;
	$an <=> $bn;
} @valueLines;
# copy just numbers
foreach (@valueLines) { my ($numb, $text) = split /\s+/; push @values, $numb; };

#print Dumper(@values);
#print Dumper(@valueLines);

my $max      = Math::BigInt->new(2)->bpow((1+$#values))->bsub(1);
my $min      = Math::BigInt->new();
my $current  = $max->copy();
my $previous = Math::BigInt->new(-1);


sub combo
{
	my ($code) = @_;
	$code = $$code->copy();
	my ($i,$val)=(0,0);
	while (! $code->is_zero())
	{
#		print STDERR "$i code: $code\n";
		$val += $values[$i] if ($code->is_odd());
		$i++;
		$code = $code->brsft(1);
	}
#	print "val: $val\n";
	return $val;
}
sub english
{
	my ($code) = @_;
	my ($i,$val,$output)=(0,0,'');
	while (! $$code->is_zero())
	{
		$val += $values[$i] if ($$code->is_odd());
		$output .= " + " . $valueLines[$i] . "\n" if ($$code->is_odd());
		$$code = $$code->brsft(1);
		$i++;
	}
	print "Result: $val can be made from:\n$output = $val\n" ;
}

if ( ! $slow )
{
# binary chop
	while ($current->bcmp($previous))
	{
#	print "current binary $current, max is $max, min is $min\n";
		$previous      = $current->copy();
		my $currentVal = combo(\$current);
		if ($currentVal>$lookFor)
		{
			print "too high $currentVal -- $current\n";
			$max      = $current->copy(); # new max
			$previous = $current->copy();
			$current = $current->badd($min)->bdiv(2);
		}
		elsif ($currentVal<$lookFor)
		{
			print "too low $currentVal -- $current\n";
			$min      = $current->copy(); # new min
			$previous = $current->copy();
			$current  = $current->badd($max)->bdiv(2);
		}
		else
		{
			print "Found answer: ";
			english(\$current) ;
			exit 0;
		}
	}
	print "No answer. Nearest was between $min:\n";
	english(\$min);
	print "and: $max \n";
	english(\$max);
}
else
{
	# slow method
	# find max single value
	my $i=0;
	$i++ while ($i<$#values && $values[$i]<$lookFor) ;
	$max = Math::BigInt->new( $values[$i] ) if ( $i<$#values ) ;
	$current = $min->copy(); # 0
	# optimise start
	$i=0;
	my $total = 0;
	$total += $values[$i++] while ($i<$#values && $total<$lookFor);
	$i=0 if (($i--) <0);
	my $min = Math::BigInt->new(2)->bpow($i);

	print "Starting from $min\n";

	$current = $min->copy(); 

	# try every combination
	my $lastDiff = $lookFor;

	print "starting " . $max->copy()->bsub($min) ." iterations...\n";
	while ($lastDiff && $current->bcmp($max))
	{
		my $thisDiff = abs(combo(\$current) - $lookFor);
		if ( $thisDiff<$lastDiff )
		{
			$lastDiff = $thisDiff;
			$previous = $current->copy();
		}
		$current++;
	}
	print "Nearest is $lastDiff out: \n";
	english(\$previous);
}

