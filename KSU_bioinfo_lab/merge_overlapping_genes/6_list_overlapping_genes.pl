#!/usr/bin/perl

use strict;
use warnings;

# usage: ./6_list_overlapping_genes.pl 5_merged_genes.txt 1_gene_names_and_locations.txt > 6a_list_of_merged_genes.txt

open IN, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
my @in = <IN>;
chomp @in;
close IN;

open NAMES, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
my %ids;
while (<NAMES>) {
  chomp;
  my $attributes = (split (/\t/))[8];
  my @attributes = split (/;/, $attributes);
  my ($name, $id);
  for (@attributes) {
    my @values = split (/=/);
    if ($values[0] eq 'Name') {
      $name = $values[1];
    }
    elsif ($values[0] eq 'ID') {
      $id = $values[1];
    }
  }
  $ids{$name} = $id;
}
close NAMES;

my @gene_names;
my %overlap;
for (@in) {
  if (/http/) {
    @gene_names = ();
  }
  elsif (/^$/) {
    for my $i (0..$#gene_names) {
      for my $j (0..$#gene_names) {
        unless ($i == $j) {
          # push (@{$overlap{$gene_names[$i]}}, $gene_names[$j]);
          $overlap{$gene_names[$i]}{$gene_names[$j]} = undef;
        }
      }
    }
  }
  else {
    push (@gene_names, &id ($_));
  }
}

for (keys %overlap) {
  my @genes = keys %{$overlap{$_}};
  push (@genes, $_);
  print join (',', sort (@genes)), "\n";
}

sub id {
  my $line = shift;
  $line =~ s/\t(.*)/$1/;
  if ($line =~ /NO NAME ASSIGNED/) {
    $line =~ s/.*\s(.*)/$1/;
    return $line;
  }
  else {
    return $ids{$line};
  }
}
