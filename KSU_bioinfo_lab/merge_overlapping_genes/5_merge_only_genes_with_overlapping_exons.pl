#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(max min);

# usage: ./5_merge_only_genes_with_overlapping_exons.pl 3_candidate_merges.txt genes_without_fasta.gff > 5_merged_genes.txt
# sample input file
# 2       http://mywebapolloserver.com/WebApollo/jbrowse/?loc=scaffold00002%3A2483066..2491059&tracks=DNA%2CAnnotations&highlight=
#         2483066 2491059 +       16F0ABC6C61FBBAAB93107FC35C8224D-8
#         2489373 2489675 +       EVM prediction scaffold00002.54
# 
# 2       http://mywebapolloserver.com/WebApollo/jbrowse/?loc=scaffold00002%3A2511530..2525164&tracks=DNA%2CAnnotations&highlight=

open TXT, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
my @txt = <TXT>;
chomp @txt;
close TXT;

# get the Name or ID of the genes of interest
my %gene;
for (@txt) {
  unless (/http/ or /^$/) {
    my @line = split (/\t/, $_);
    if (/NO NAME ASSIGNED/) {
      $line[4] =~ s/NO NAME ASSIGNED: //;
      $gene{$line[4]} = 'ID';
    }
    else {
      $gene{$line[4]} = 'Name';
    }
  }
}

# get the exon coordinates for the genes of interest
my $gene_of_interest;
open GFF, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
while (<GFF>) {
  unless (/^#/ or /^\s*$/) {
    chomp;
    my @line = split (/\t/, $_);
    if ($line[2] eq 'gene') {
      # get the name and id of the gene
      my $gene_ref = &gene_name_and_id (\$line[8]);
      # if this is a gene of interest, change the value of %gene for this key to an empty array
      if ($gene{$gene_ref->{ID}}) {
        $gene_of_interest = 'NO NAME ASSIGNED: ' . $gene_ref->{ID};
      }
      elsif ($gene{$gene_ref->{Name}}) {
        $gene_of_interest = $gene_ref->{Name};
      }
      else {
        $gene_of_interest = '';
      }
      $gene{$gene_of_interest} = () if ($gene_of_interest);
    }
    elsif ($gene_of_interest and $line[2] eq 'exon') {
      push (@{$gene{$gene_of_interest}}, [@line[3,4]]);
    }
  }
}
close GFF;

# determine which overlaps to keep
my (@genes, $url);
for (@txt) {
  if (/http/) {
    s/\d+\t(http.*)/$1/;
    $url = $_;
    @genes = ();
  }
  elsif (/^\s*$/) {
    my %overlaps;
    for my $i (0..$#genes) {
      for my $j ($i + 1..$#genes) {
        if (&overlap ($genes[$i], $genes[$j])) {
          push (@{$overlaps{$genes[$i]}}, $genes[$j]);
          push (@{$overlaps{$genes[$j]}}, $genes[$i]);
        }
      }
    }
    # get the list of overlapping genes
    for my $gene_name (keys %overlaps) {
      my @overlapping_genes = &overlapping_genes ($gene_name, \%overlaps);
      if (scalar (@overlapping_genes) > 1) {
        print scalar (@overlapping_genes), "\t$url\n";
        # put the gene names in a set to eliminate duplicate printing of a gene
        my %print_genes;
        $print_genes{$_} = undef for (@overlapping_genes);
        # print the genes
        print "\t$_\n" for (keys %print_genes);
        print "\n";
      }
    }
  }
  else {
    push (@genes, (split (/\t/, $_))[4]);
  }
}

# returns the list of genes that overlap
sub overlapping_genes {
  my ($gene_a, $overlaps) = @_;
  my @genes;
  push (@genes, $gene_a);
  while (my $gene_b = pop (@{$overlaps->{$gene_a}})) {
    push (@genes, &overlapping_genes ($gene_b, $overlaps)) unless (scalar grep $_ eq $gene_b, @genes);
  }
  return @genes;
}

# returns 1 if any exon from 1st gene overlaps any exon from 2nd gene, or 0 otherwise
sub overlap {
  my ($gene_a, $gene_b) = @_;
  for my $exon_in_a (@{$gene{$gene_a}}) {
    for my $exon_in_b (@{$gene{$gene_b}}) {
      return 1 if (($exon_in_b->[0] <= $exon_in_a->[0] and $exon_in_a->[0] <= $exon_in_b->[1]) or ($exon_in_a->[0] <= $exon_in_b->[0] and $exon_in_b->[0] <= $exon_in_a->[1]));
    }
  }
  return 0;
}

# returns the Name and ID of the gene
sub gene_name_and_id {
  my $ref = shift;
  my %result;
  my @attributes = split (/;/, $$ref);
  for (@attributes) {
    if (/Name/ or /ID/) {
      my @attribute = split (/=/, $_);
      $result{$attribute[0]} = $attribute[1];
    }
  }
  return \%result;
}
