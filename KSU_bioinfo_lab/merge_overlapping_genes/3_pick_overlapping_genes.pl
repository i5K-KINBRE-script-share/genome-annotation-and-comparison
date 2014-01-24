#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(max min);

# usage: ./3_pick_overlapping_genes.pl 2_overlapping_genes.txt > 3_candidate_merges.txt
# sample input file
# 2 genes overlap on scaffold00001 at 434009 - 450145:
# 	434009	450134	+	EVM prediction scaffold00001.12
# 	434152	450145	+	A5A282675A8ADECA815EC6A557E8F9BC-1
# 
# 2 genes overlap on scaffold00001 at 452181 - 456401:

open IN, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
my @in = <IN>;
chomp @in;
close IN;

# process each region with overlapping genes
my @genes;
for (@in) {
  if (/^$/) {
    &pick_genes (\@genes);
  }
  else {
    push (@genes, $_);
  }
}

sub pick_genes {
  my $lines = shift;
  # split the genes into manually currated and pasa
  my (%mc_genes, %pasa_genes);
  for (my $i = 1; $i < scalar @{$lines}; $i++) {
    my @fields = split (/\t/, $lines->[$i]);
    if ($fields[4] =~ /EVM/ or $fields[4] =~ /NO NAME ASSIGNED/) {
      push (@{$pasa_genes{$fields[4]}}, (@fields[1..3]));
    }
    else {
      push (@{$mc_genes{$fields[4]}}, (@fields[1..3]));
    }
  }
  # find closest pasa gene to each manually currated gene
  for my $mc_gene (keys %mc_genes) {
    my %dist;
    # calculate the 'distance' between the manually curated gene and each pasa gene that has the same orientation
    for my $pasa_gene (keys %pasa_genes) {
      if ($mc_genes{$mc_gene}->[2] eq $pasa_genes{$pasa_gene}->[2]) {
        $dist{$pasa_gene} = abs ($mc_genes{$mc_gene}->[0] - $pasa_genes{$pasa_gene}->[0]) + abs ($mc_genes{$mc_gene}->[1] - $pasa_genes{$pasa_gene}->[1]);
      }
    }
    # find the minimum 'distance'
    my $min = min (values %dist);
    # select the pasa gene(s) with minimum distance
    for my $pasa_gene (keys %dist) {
      if ($dist{$pasa_gene} == $min) {
        $_ = $lines->[0];
        s/.*(scaffold\d+).*/$1/;
        print 'http://mywebapolloserver.com/WebApollo/jbrowse/?loc=', $_, '%3A', min ($mc_genes{$mc_gene}->[0], $pasa_genes{$pasa_gene}->[0]), '..';
        print max ($mc_genes{$mc_gene}->[1], $pasa_genes{$pasa_gene}->[1]), '&tracks=DNA%2CAnnotations&highlight=', "\n";
        print "\t", join ("\t", @{$mc_genes{$mc_gene}}), "\t$mc_gene\n";
        print "\t", join ("\t", @{$pasa_genes{$pasa_gene}}), "\t$pasa_gene\n\n";
      }
    }
  }
  # clear the @genes array
  @genes = ();
}
