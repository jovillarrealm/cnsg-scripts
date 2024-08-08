#!/bin/bash

# Descripción clara del script
echo "Crea bases de datos de nucleótidos o proteínas para BLAST a partir de archivos FASTA en una subcarpeta especificada."
echo "Las bases de datos se crean en un directorio 'dbs'."

# Solicitar al usuario el directorio de los archivos FASTA
echo "Ingrese el nombre de la subcarpeta que contiene los archivos FASTA:"
#read -r inicio
inicio="predb"
# Solicitar el tipo de base de datos
#echo "El tipo de base de datos es de nucleótidos (y) o proteínas (n)? "
#read -r npdbtype
npdbtype="nucl"
npdbtype=${npdbtype,,}  # Convertir a minúsculas para evitar problemas de mayúsculas/minúsculas

dbdir="dbs"
# Crear el directorio 'dbs' si no existe
if [ ! -d dbs ]; then
  mkdir $dbdir
fi

find . -wholename "./$inicio/*.fasta" -type f  

# Buscar archivos FASTA en el directorio especificado y crear bases de datos
find . -wholename "./$inicio/*.fasta" -type f  | \
  xargs -pI {} parallel -j 8 "makeblastdb -in "{}" -dbtype $npdbtype -out "$dbdir/$( basename {} )""


