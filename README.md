genome-annotation-and-comparison
================================

KSU_bioinfo_lab
---------------

Count_fastas.pl - see assembly_quality_stats_for_multiple_assemblies.pl

assembly_quality_stats_for_multiple_assemblies.pl - This script runs a slightly modified version of Joseph Fass' Count_fasta.pl (original available at http://wiki.bioinformatics.ucdavis.edu/index.php/Count_fasta.pl ) on a fasta file from each assembly. It then creates comma separated file called assembly_metrics.csv listing the N25,N50,N75, cumulative contig length, and number of contigs for each assembly (also download Count_fastas.pl and change $path_to_Count_fastas on line 13 of assembly_quality_stats_for_multiple_assemblies.pl).
