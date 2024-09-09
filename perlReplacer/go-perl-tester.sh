#!/bin/bash

files=$(find ../GENOMIC/ -type f )

for genome in $files
do
 (./count_fasta_cnsg.pl "$genome" | tail -n 12) > perl.out
 (./count-fasta-go/count-fasta-go "$genome" data.csv) > go.out
 diff -w perl.out go.out > diffs
done

for genome in $files
do
 (./count_fasta_cnsg.pl "$genome" | tail -n 12) > perl.out
 (./rs-count "$genome" data.csv) > go.out
 diff -w perl.out go.out > diffs
done