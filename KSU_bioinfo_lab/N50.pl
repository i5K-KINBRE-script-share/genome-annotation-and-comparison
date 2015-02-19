#!/usr/bin/perl
# USAGE: N50.pl FASTA
# DESCRIPTION: Script calculates N50 for a fasta sequence file
use warnings;
use strict;
use 5.010;
##############################################################################
# OPEN FASTA FILE
##############################################################################
my $infile=$ARGV[0];
open(FILE, "<$infile");

##############################################################################
# INITIALIZE VARIABLES AND ARRAYS
##############################################################################
my $length=0; #Stores length of each sequence
my $total_length=0;
my @lengths;

##############################################################################
# LOOP THROUGH FASTA TO FIND LENGTHS
##############################################################################
while(<FILE>)
{
    ##############################################################################
    # FOR HEADERS:
    # if line is a header add length of the last contig to total length and append
    # the length of the last contig to an array of contig lengths
    ##############################################################################
	if (/^>/) # If this is a sequence ID, we need to dump length to total and @lengths
	{
		if ($length > 0) # skips only the first header
		{
			$total_length += $length; # Add $length to the total
			push (@lengths, $length); # Append length to the array of contig lengths
            $length=0; #Reset length for the next contig
		}
		
	}
    ##############################################################################
    # FOR SEQUENCE:
    # if line is sequence remove whitespace and add the length of the string to
    # the contig length
    ##############################################################################
	else
	{
		s/\s//g; # remove whitespace characters
		$length += length($_); # add length of this line to contig length
	}
    ##############################################################################
    # FOR THE LAST SEQUENCE:
    # add length of the last contig to total length and append the length of the
    # last contig to an array of contig lengths
    ##############################################################################
    if (eof)
    {
        $total_length+=$length; #Add $length to the total
        push (@lengths, $length); # Append length to the array of contig lengths
    }
}

##############################################################################
# CALCULATE N50:
# Now calculate the N50 from the array of contig lengths and the total length
##############################################################################
@lengths=sort{$b<=>$a} @lengths; #Sort lengths largest to smallest

my $current_length; #create a new variable for N50
my $fraction=$total_length;
foreach(my $j=0; $fraction>$total_length/2; $j++) #until $fraction is greater than half the total length increment the index value $j for @lengths
{
    $current_length=$lengths[$j];
    $fraction -= $current_length; # subtract current length from $fraction
}
say "N50: $current_length";
say "Total length: $total_length";


