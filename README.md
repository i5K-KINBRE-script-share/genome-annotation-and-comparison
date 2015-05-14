genome-annotation-and-comparison
================================

KSU_bioinfo_lab
---------------

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.17587.svg)](http://dx.doi.org/10.5281/zenodo.17587)

Jennifer Shelton et al.. (2015). genome-annotation-and-comparison: genome-annotation-and-comparison tools Version 1.0.0. Zenodo. 10.5281/zenodo.17587

**Count_fastas.pl** - see assembly_quality_stats_for_multiple_assemblies.pl

**assembly_quality_stats_for_multiple_assemblies.pl** - This script runs a slightly modified version of Joseph Fass' Count_fasta.pl (original available at http://wiki.bioinformatics.ucdavis.edu/index.php/Count_fasta.pl ) on a fasta file from each assembly. It then creates comma separated file called assembly_metrics.csv listing the N25,N50,N75, cumulative contig length, and number of contigs for each assembly (also download Count_fastas.pl and change $path_to_Count_fastas on line 13 of assembly_quality_stats_for_multiple_assemblies.pl).

       USAGE: perl assembly_quality_stats_for_multiple_assemblies.pl [fasta_file or files]
       
**fix_ogs_gff.pl** - This script takes a GFF file with lines in random order and outputs the lines in 'hierarchical' order with genes separated by ### directive to indicate that all forward references to feature IDs that have been seen to this point have been resolved. Note that with this script the order of the genes is not preserved.

**chromosome_from_scaffold_agp.pl** - This script takes an AGP file, superscaffolds from contigs, and another AGP file, scaffolds from contigs, and generates an AGP file, superscaffolds from scaffolds.

**scaffold_map.pl** - This script creates the mapping between the scaffold names from a previous assembly and the scaffold names of the current assembly.
