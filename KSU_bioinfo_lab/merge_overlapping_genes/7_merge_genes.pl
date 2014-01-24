#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(max min);

# usage: ./7_merge_genes.pl genes_without_fasta.gff 6b_uniq_list_of_merged_genes.txt > 7_merged_annotations_without_fasta.gff

open IDS, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
my %ids;
while (<IDS>) {
  chomp;
  my @ids = split (/,/, $_);
  for my $i (0..$#ids) {
    for my $j (0..$#ids) {
      push (@{$ids{$ids[$i]}}, $ids[$j]) unless ($i == $j);
    }
  }
}
close IDS;

my (@gene_lines, $ok_to_print, %genes, $gene_id);
open GFF, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
while (<GFF>) {
  chomp;
  if (/^###$/) {				# end of gene
    if ($ok_to_print) {
      if ($gene_id eq '') {			# non-merged gene
        for (@gene_lines) {
          print join ("\t", @{$_}), "\n";
        }
        print "###\n";
      }
      else {					# merged gene
        push (@{$genes{$gene_id}}, [@{$_}]) for (@gene_lines);
        &print_merged_genes ($gene_id);
      }
    }
    else {					# this gene doesn't have all the other genes with which it should be merged
      push (@{$genes{$gene_id}}, [@{$_}]) for (@gene_lines);
    }
    @gene_lines = ();
  }
  elsif (/^#/) {				# header comments
    print "$_\n";
  }
  else {					# non header comments, non end of gene
    my @line = split (/\t/, $_);
    if ($line[2] eq 'gene') {			# gene line
      my $attributes = &attributes ($line[8]);
      if (defined ($ids{$attributes->{ID}})) {	# this gene needs to be merged
        $ok_to_print = &ready ($attributes->{ID});	# 1 if all the other genes with which it should be merged have been loaded, 0 otherwise
        $gene_id = $attributes->{ID};
      }
      else {					# this gene doesn't need to be merged
        $ok_to_print = 1;
        $gene_id = '';
      }
    }
    push (@gene_lines, [@line]);
  }
}
close GFF;

sub attributes {
  my $attributes = shift;
  my @attributes = split (';', $attributes);
  my %attributes;
  for (@attributes) {
    my @values = split ('=', $_);
    $attributes{$values[0]} = $values[1];
  }
  return \%attributes;
}

sub ready {
  my $id = shift;
  for (@{$ids{$id}}) {
    return 0 if (!defined ($genes{$_}));
  }
  return 1;
}

sub print_merged_genes {
  my $id = shift;
  my ($start, $end) = ($genes{$id}->[0][3], $genes{$id}->[0][4]);
  my $attributes = &attributes ($genes{$id}->[0][8]);

  # get the coordinates for the merged gene, and all attributes different than ID and Name
  for my $other_id (@{$ids{$id}}) {
    $start = min ($start, $genes{$other_id}->[0][3]);
    $end = max ($end, $genes{$other_id}->[0][4]);

    my $other_attributes = &attributes ($genes{$other_id}->[0][8]);
    for my $tag (keys %{$other_attributes}) {
      if ($tag ne 'Name' and $tag ne 'ID') {
        if (defined ($attributes->{$tag})) {
          $attributes->{$tag} .= ' ||| ' . $other_attributes->{$tag};
        }
        else {
          $attributes->{$tag} = $other_attributes->{$tag};
        }
      }
    }
  }
  # print the 'gene' line
  print join ("\t", @{$genes{$id}->[0]}[0..2]), "\t$start\t$end\t", join ("\t", @{$genes{$id}->[0]}[5..7]), "\t";
  for my $tag (keys %{$attributes}) {
    print "$tag=$attributes->{$tag};";
  }
  print "\n";
  # print the other lines from the gene with ID=$id
  for my $i (1..$#{$genes{$id}}) {
    print join ("\t", @{$genes{$id}->[$i]}), "\n";
  }
  # print the other lines from the gene(s) with ID=$other_id
  for my $other_id (@{$ids{$id}}) {
    for my $i (1..$#{$genes{$other_id}}) {
      my $line = join ("\t", @{$genes{$other_id}->[$i]});
      $line =~ s/$other_id/$id/g;
      print "$line\n";
    }
  }
  print "###\n";
}
