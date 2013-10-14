#!/usr/bin/perl

use strict;
use warnings;

# usage: ./fix_ogs_gff.pl input.gff > output.gff
# Takes a GFF file with lines in random order and outputs the lines in 'hierarchical' order with genes separated by ### directive
# to indicate that all forward references to feature IDs that have been seen to this point have been resolved.
# Note: The order of the genes is not preserved.
# sample input file
# ChLG10	OGS_lifted	three_prime_UTR	5620	5622	.	-	.	Parent=TC012949-RA
# ChLG10	OGS_lifted	gene	5620	15166	.	-	.	ID=TC012949;
# ChLG10	OGS_lifted	mRNA	5620	15166	.	-	.	ID=TC012949-RA;Parent=TC012949;Name=TC012949-RA
# ChLG10	OGS_lifted	CDS	5623	6221	.	-	2	Parent=TC012949-RA
# ChLG10	OGS_lifted	intron	6222	6844	.	-	.	Parent=TC012949-RA;
# ChLG10	OGS_lifted	CDS	6845	7140	.	-	1	Parent=TC012949-RA
# ChLG10	OGS_lifted	intron	7141	14912	.	-	.	Parent=TC012949-RA;
# ChLG10	OGS_lifted	CDS	14913	15166	.	-	0	Parent=TC012949-RA
# ChLG10	OGS_lifted	three_prime_UTR	17251	17253	.	-	.	Parent=TC012948-RA
# ChLG10	OGS_lifted	gene	17251	18338	.	-	.	ID=TC012948;
# ChLG10	OGS_lifted	mRNA	17251	18338	.	-	.	ID=TC012948-RA;Parent=TC012948;Name=TC012948-RA
# ChLG10	OGS_lifted	CDS	17254	18064	.	-	1	Parent=TC012948-RA
# ChLG10	OGS_lifted	intron	18065	18126	.	-	.	Parent=TC012948-RA;
# ChLG10	OGS_lifted	CDS	18127	18338	.	-	0	Parent=TC012948-RA
# ChLG10	OGS_lifted	CDS	20400	20856	.	+	0	Parent=TC012951-RA
# sample output file
# ChLG10  OGS_lifted      gene    5620    15166   .       -       .       ID=TC012949;
# ChLG10  OGS_lifted      mRNA    5620    15166   .       -       .       ID=TC012949-RA;Parent=TC012949;Name=TC012949-RA
# ChLG10  OGS_lifted      CDS     5623    6221    .       -       2       Parent=TC012949-RA
# ChLG10  OGS_lifted      CDS     14913   15166   .       -       0       Parent=TC012949-RA
# ChLG10  OGS_lifted      intron  6222    6844    .       -       .       Parent=TC012949-RA;
# ChLG10  OGS_lifted      CDS     6845    7140    .       -       1       Parent=TC012949-RA
# ChLG10  OGS_lifted      three_prime_UTR 5620    5622    .       -       .       Parent=TC012949-RA
# ChLG10  OGS_lifted      intron  7141    14912   .       -       .       Parent=TC012949-RA;
# ###
# hLG10  OGS_lifted      gene    17251   18338   .       -       .       ID=TC012948;
# ChLG10  OGS_lifted      mRNA    17251   18338   .       -       .       ID=TC012948-RA;Parent=TC012948;Name=TC012948-RA
# ChLG10  OGS_lifted      intron  18065   18126   .       -       .       Parent=TC012948-RA;
# ChLG10  OGS_lifted      CDS     18127   18338   .       -       0       Parent=TC012948-RA
# ChLG10  OGS_lifted      three_prime_UTR 17251   17253   .       -       .       Parent=TC012948-RA
# ChLG10  OGS_lifted      CDS     17254   18064   .       -       1       Parent=TC012948-RA
# ###

my %line;	# key = ID, value = (Parent, WholeLine, Used)
my $id = 0;	# identifier for input lines without one

open GFF, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
while(<GFF>) {
  chomp;

  unless(/^#/ or /^\s*$/) {	# skip blank or comment lines
    # read attributes
    my %attr;
    my @attributes = split(";", (split)[8]);
    for my $attribute(@attributes) {
      my($tag, $value) = split("=", $attribute);
      $attr{$tag} = $value;
    }
    if(!defined($attr{ID})) {
      $attr{ID} = $id++;
    }
  
    # add input line to %line
    $line{$attr{ID}} = [$attr{Parent}, $_, 0];
  }
}
close GFF;

for my $ID (keys %line) {
  if(!defined($line{$ID}[0])) {	# gene line
    # output gene line
    print "$line{$ID}[1]\n";
    # mark the line as used
    $line{$ID}[2] = 1;
    # output its children
    &output_children($ID);
    # output ### directive
    print "###\n";
  }
}

sub output_children {
  my $parent_ID = shift;
  for my $ID (keys %line) {
    if(!$line{$ID}[2] && defined($line{$ID}[0]) && $line{$ID}[0] eq $parent_ID) {
      # output line
      print "$line{$ID}[1]\n";
      # mark the line as used
      $line{$ID}[2] = 1;
      # output its children
      &output_children($ID);
    }
  }
}
