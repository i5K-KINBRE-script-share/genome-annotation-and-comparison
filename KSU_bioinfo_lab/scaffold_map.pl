#!/usr/bin/perl

use strict;
use warnings;

# usage: ./scaffold_map.pl scaffold_from_component.agp contig.map previous.agp > scaffold.map | sed 's/Scaffold//' | sort -k 2 -n | sed 's/\t/\tScaffold/' > scaffold.map
# Creates the mapping between the previous scaffold names and the current scaffold names.
# sample input
#ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas_scaffold_from_component.agp
###agp-version   2.0
## ORGANISM: Tribolium castaneum
## TAX_ID: 7070
## ASSEMBLY NAME: Tcas_4.0
## ASSEMBLY DATE: 10-December-2012
## GENOME CENTER: Bioinformatics Center at Kansas State University
## DESCRIPTION: AGP specifying the assembly of scaffolds from WGS contigs
#Scaffold1	1	1125	1	W	tcas_1	1	1125	+
#Scaffold1	1126	2247	2	N	1122	scaffold	yes	unspecified
#Scaffold1	2248	5116	3	W	tcas_2	1	2869	+
#
#ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/contig.map
#Contig name
#Tcas3.0	Tcas4.0
#AAJJ01008955	tcas_1
#AAJJ01006226	tcas_2
#AAJJ01003069	tcas_3
#AAJJ01004219	tcas_4
#AAJJ01004943	tcas_4
#AAJJ01005976	tcas_5
#AAJJ01001748	tcas_6
#AAJJ01005646	tcas_7
#
# sample output
#ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/scaffold.map
#Scaffold name
#Tcas3.0	Tcas4.0
#NW_001092851.1	Scaffold1
#NW_001092852.1	Scaffold1
#NW_001092853.1	Scaffold1
#DS497721.1	Scaffold2
#NW_001093448.1	Scaffold2
#DS497720.1	Scaffold3
#DS497730.1	Scaffold3
#NW_001092764.1	Scaffold3

# read input files
open NEW_AGP, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
open CONTIG_MAP, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
open OLD_AGP, '<', $ARGV[2] or die "Couldn't open $ARGV[2]: $!";

# $contig_map{new_contig_name} = (old_contig_names)
my %contig_map;
while(<CONTIG_MAP>) {
  if(/^AAJJ/) {
    chomp;
    my($old_contig_name, $new_contig_name) = split;
    push(@{$contig_map{$new_contig_name}}, $old_contig_name);
  }
}
close CONTIG_MAP;

# $new_scaffold_map{new_scaffold_name} = (new_contig_names)
my %new_scaffold_map;
while(<NEW_AGP>) {
  unless(/^#/) {
    chomp;
    my @agp_line = split;
    if($agp_line[4] eq "W") {
      push(@{$new_scaffold_map{$agp_line[0]}}, $agp_line[5]);
    }
  }
}
close NEW_AGP;

# $old_scaffold_map{old_contig_name} = old_scaffold_name
my %old_scaffold_map;
while(<OLD_AGP>) {
  if(/AAJJ/) {
    chomp;
    my @agp_line = split;
    $old_scaffold_map{$agp_line[5]} = $agp_line[1];
  }
}
close OLD_AGP;

# map new_scaffol_names to old_scaffold_names
# $scaffold_map{new_scaffold_name} = (old_scaffold_name)
my %scaffold_map;
for my $new_scaffold_name (keys %new_scaffold_map) {
  for my $new_contig_name (@{$new_scaffold_map{$new_scaffold_name}}) {
    for my $old_contig_name (@{$contig_map{$new_contig_name}}) {
      push(@{$scaffold_map{$new_scaffold_name}}, $old_scaffold_map{$old_contig_name});
    }
  }
}

# output the map
for my $new_scaffold_name (sort keys %scaffold_map) {
  my $previous_old_scaffold_name = '';
  for my $old_scaffold_name (sort @{$scaffold_map{$new_scaffold_name}}) {
    if($old_scaffold_name ne $previous_old_scaffold_name) {
      $previous_old_scaffold_name = $old_scaffold_name;
      print "$old_scaffold_name\t$new_scaffold_name\n";
    }
  }
}
