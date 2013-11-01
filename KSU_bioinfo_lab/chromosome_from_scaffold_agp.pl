#!/usr/bin/perl

use strict;
use warnings;

# usage: ./chromosome_from_scaffold_agp.pl chromosome_from_component.agp scaffold_from_component.agp > chromosome_from_scaffold.agp
# Takes an AGP file, superscaffolds from contigs, and another AGP file, scaffolds from contigs, and generates an AGP file, superscaffolds from scaffolds.
# sample input
#ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas_chromosome_from_component.agp
###agp-version   2.0
## ORGANISM: Tribolium castaneum
## TAX_ID: 7070
## ASSEMBLY NAME: Tcas_4.0
## ASSEMBLY DATE: 10-December-2012
## GENOME CENTER: Bioinformatics Center at Kansas State University
## DESCRIPTION: AGP specifying the assembly of chromosomes from WGS contigs
#ChLGX	1	18146	1	W	tcas_4417	1	18146	+
#ChLGX	18147	18156	2	N	10	scaffold	yes	unspecified
#ChLGX	18157	114777	3	W	tcas_4418	1	96621	+
#
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
#sample output
#ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas_chromosome_from_scaffold.agp
###agp-version   2.0
## ORGANISM: Tribolium castaneum
## TAX_ID: 7070
## ASSEMBLY NAME: Tcas_4.0
## ASSEMBLY DATE: 10-December-2012
## GENOME CENTER: Bioinformatics Center at Kansas State University
## DESCRIPTION: AGP specifying the assembly of chromosomes from scaffolds
#ChLGX	1	255309	1	Scaffold144	W	1	255309	+
#ChLGX	255310	255409	2	U	100	scaffold	yes	map
#ChLGX	255410	499204	3	Scaffold154	W	1	243795	+

# load the input AGP files
open SSC, '<', $ARGV[0], or die "Couldn't open $ARGV[0]: $!";
open SC, '<', $ARGV[1], or die "Couldn't open $ARGV[1]: $!";

my @ssc = <SSC>;
my @sc = <SC>;

close SSC;
close SC;

chomp(@ssc);
chomp(@sc);

# for contigs, $sc_summary{contig_name} = [scaffold_name, orientation]
my %sc_summary;
for(@sc) {
  unless(/^#/) {
    my @sc_line = split;
    $sc_summary{$sc_line[5]} = [$sc_line[0], $sc_line[8]] if $sc_line[4] eq "W";
  }
}

my($current_super_scaffold, $current_scaffold, $current_orientation, $start, $end, $id) = ('', '', '', '', '', 0);
my @ssc_gap_line;
my @ssc_line;

for my $i (0..$#ssc) {
  $_ = $ssc[$i];
  unless(/^#/) {
    @ssc_line = split;
    if($ssc_line[4] eq "W") {	# contig line
      my $corresponding_scaffold = $sc_summary{$ssc_line[5]};
      if($current_scaffold ne $corresponding_scaffold->[0]) {
        if($current_scaffold ne '') {
          # output the scaffold line
          print "$current_super_scaffold\t$start\t$end\t$id\t$current_scaffold\t$ssc_line[4]\t1\t", $end - $start + 1, "\t$current_orientation\n";
          # output gap line, if there's one
          if((split("\t", $ssc[$i-1]))[0] eq $current_super_scaffold && (split("\t", $ssc[$i-1]))[4] eq "U") {
            $id++;
            print join("\t", (split("\t", $ssc[$i-1]))[0,1,2]), "\t$id\t", join("\t", (split("\t", $ssc[$i-1]))[4,5,6,7,8]), "\n";
          }
        }
        $id = 0 if $current_super_scaffold ne $ssc_line[0];
        $current_super_scaffold = $ssc_line[0];
        $current_scaffold = $corresponding_scaffold->[0];
        $current_orientation = $corresponding_scaffold->[1];
        $start = $ssc_line[1];
        $end = $ssc_line[2];
        $id++;
      }
      else {
        $end = $ssc_line[2];
      }
      elsif($current_orientation ne $corresponding_scaffold->[1]) {
        print "There are contigs with different orrientations!!!\n";
      }
    }
    else {			# gap line
      @ssc_gap_line = @ssc_line;
    }
  }
}

# output the last scaffold
print "$current_super_scaffold\t$start\t$end\t$id\t$current_scaffold\t$ssc_line[4]\t1\t", $end - $start + 1, "\t$current_orientation\n";
