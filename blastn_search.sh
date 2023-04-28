#!/bin/bash
echo "Asume que los .fasta query están en un subdirectorio 'querys' y las bases de datos en 'dbs'"
for db_path in dbs/*
do
curdb=$(basename "$db_path")
echo "Nombre de la base de datos: $curdb"
#read dbname

    query_folder="querys"

    for file_path in "$query_folder"/*.fasta
    do  
        file=$(basename "$file_path")
        results="search results/$curdb"
        result="$results/$file.out"
        mkdir -p "$results"
        blastn -query "$file_path" -db "$db_path/$curdb" -out "$result" -outfmt 6 -evalue 1e-50
        echo "Resultados en: $result"
    done
done