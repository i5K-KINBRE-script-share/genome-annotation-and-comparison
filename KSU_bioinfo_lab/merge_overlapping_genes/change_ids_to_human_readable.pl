#!/usr/bin/perl

use strict;
use warnings;

# usage: ./change_ids_to_human_readable.pl genes_without_fasta.gff Msex2.00001.all.id.map > Msex2.00001.gff

open IDS, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
my %ids;
while (<IDS>) {
  chomp;
  my @ids = split ("\t", $_);
  $ids{$ids[0]} = $ids[1];
}
close IDS;

open GFF, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
while (<GFF>) {
  chomp;
  unless (/^#/) {
    my $id = &id ($_);
    s/$id->{Parent}/$ids{$id->{Parent}}/g if (defined ($id->{Parent}) and defined ($ids{$id->{Parent}}));
    s/$id->{ID}/$ids{$id->{ID}}/g if (defined ($ids{$id->{ID}}));
  }
  print "$_\n";
}
close GFF;

sub id {
  my $line = shift;
  my %attributes;
  my @line = split ("\t", $line);
  my @attributes = split (/;/, $line[8]);
  for (@attributes) {
    my @attribute = split (/=/, $_);
    $attributes{$attribute[0]} = $attribute[1];
  }
  return \%attributes;
}
