#!/bin/sh
echo "De los .fasta que estan en "
read -r inicio
for filt_seq in "$inicio"*/*.fasta
do
    file=$(basename "$filt_seq")
    #directorio=$(dirname "$filt_seq")
    echo "Para $file"
    results="alineado"
    mkdir -p $results
    mafft --auto "$filt_seq" > "$results/aln$file"
    echo "$file hecho"
done
