#!/bin/bash

## 1: get the name of the genes from the GFF file, and sort them by scaffold name and then by start value
awk '$3 == "gene"' genes_without_fasta.gff | sort -k1,1 -k4n > 1_gene_names_and_locations.txt

## 2: find overlapping genes based solely on the start and stop coordinates
perl 2_find_overlapping_genes.pl 1_gene_names_and_locations.txt > 2_overlapping_genes.txt

## 3: out of the overlapping genes pick the overlaps with the same orientation
perl 3_pick_overlapping_genes.pl 2_overlapping_genes.txt > 3_candidate_merges.txt

## 4: find genes that overlap two or more genes
grep -v http 3_candidate_merges.txt | grep -v '^$' | cut -f 5 | sort | sed 's/ /_/g' | awk '{arr[$0]++} END {for(no in arr) {print no, "\t", arr[no]}}' | awk '$2 > 1' | sed 's/_/ /g' > 4_duplicate_genes.txt

## 5: merge only genes with overlapping exons
perl 5_merge_only_genes_with_overlapping_exons.pl 3_candidate_merges.txt genes_without_fasta.gff > 5_merged_genes.txt

## 6: get the list of overlapping gene names
perl 6_list_overlapping_genes.pl 5_merged_genes.txt 1_gene_names_and_locations.txt > 6a_list_of_merged_genes.txt
sort 6a_list_of_merged_genes.txt | uniq > 6b_uniq_list_of_merged_genes.txt

## 7: merge genes
perl 7_merge_genes.pl genes_without_fasta.gff 6b_uniq_list_of_merged_genes.txt > 7_merged_annotations_without_fasta.gff

## 8: delete temporary txt files
rm *.txt
