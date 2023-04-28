#!/bin/sh
echo "Crea bases de datos de nucleotidos 'nucl' para blastn"
echo "A partir de los fasta que inicien con lo que les diga el usuario, hacen bases de datos con el nombre que diga el usuario"
echo "Va a leer solo los archivos .fasta en esta carpeta"
echo "Donde están los tejidos? (nombre de subcarpeta)"
read -r inicio 
for DB in "$inicio"*/*.fasta
do
    echo "Para $DB"
    echo "Nombre de la base de datos (nombre sin extensiones y .fasta ): "
    read -r db_name
    db_path="dbs/$db_name/$db_name"
    makeblastdb -in "$DB" -dbtype nucl -out "$db_path" #nucl porque es una base de datos de nucleotidos
    echo "$db_name hecho"
done
