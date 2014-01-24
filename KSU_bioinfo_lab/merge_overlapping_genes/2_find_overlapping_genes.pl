#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(max min);

# usage: ./2_find_overlapping_genes.pl 1_gene_names_and_locations.txt > 2_overlapping_genes.txt

open IN, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
my %lines;
while (<IN>) {
  chomp;
  my @line = (split (/\t/, $_))[0,3,4,6,8];	# scaffold name, start, end, orientation, comments
  push (@{$lines{$line[0]}{$line[3]}}, [@line[1,2,4]]);
}
close IN;

for my $scaffold (keys %lines) {
  my @genes = ();
  my ($start, $end) = (0, 0);
  for my $orientation (keys %{$lines{$scaffold}}) {
    for my $line (@{$lines{$scaffold}{$orientation}}) {
      my $name = &name ($line->[2]);
      # if this gene and previous gene(s) overlap
      if ($start <= $line->[0] and $line->[0] <= $end) {
        # update the start and end coordinates of the overlapping region
        $start = min ($start, $line->[0]);
        $end = max ($end, $line->[1]);
      }
      # if this gene and previous gene(s) do not overlap
      else {
        # if there are any overlapping genes, print them
        if (scalar @genes > 1) {
          print scalar (@genes) , "\t", 'http://agripestbase.org:8080/WebApollo_Msex/jbrowse/?loc=', $scaffold, '%3A', $start, '..', $end, '&tracks=DNA%2CAnnotations&highlight=', "\n";
          print join ("\n", @genes), "\n\n";
        }
        # reset values
        $start = $line->[0];
        $end = $line->[1];
        @genes = ();
      }
      # add this gene to the list of overlapping genes
      push (@genes, "\t$line->[0]\t$line->[1]\t$orientation\t$name");
    }
  }
  # 'end-of-scaffold' genes, not printed yet
  if (scalar @genes > 1) {
    print scalar (@genes) , "\t", 'http://agripestbase.org:8080/WebApollo_Msex/jbrowse/?loc=', $scaffold, '%3A', $start, '..', $end, '&tracks=DNA%2CAnnotations&highlight=', "\n";
    print join ("\n", @genes), "\n\n";
    # reset values
    ($start, $end) = (0,0);
    @genes = ();
  }
}

sub name {
  my $comments = shift;
  my @comments = split (";", $comments);
  my ($name, $id);
  for (@comments) {
    if (/^ID=/) {
      s/^ID=//;
      $id = $_;
    }
    elsif (/^Name=/) {
      s/^Name=//;
      $name = $_;
    }
  }
  $name = "NO NAME ASSIGNED: " . $id if ($name =~ /NO NAME ASSIGNED/);
  return $name;
}
