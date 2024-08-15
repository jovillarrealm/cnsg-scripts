#!/bin/bash

# Check for required arguments
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo ""
    echo "Uso: $0 <input_file> <output_dir> <api_key_file>"
    echo ""
    echo "Este programa asume que el 'datasets' de la ncbi está instalado y se llama con 'datasets'"
    echo "Primera área de mejora, pasar flags de acá a datasets"
    echo "De momento solo se maneja --api-key indirectamente"
    echo ""
    exit 1
fi
input_file="$1"
output_dir="$2"
if [ $# -eq 2 ]; then
    num_process=3
fi
if [ $# -eq 3 ]; then
    num_process=10
    api_key=$( cat "$3" )
    echo "API Key:""$api_key"" se van a poder, máximo 10"
fi
zip_dir="$output_dir/tmp"
genomic_dir="$output_dir/GENOMIC"
# Create temporary and output directories
tmp_dir="$output_dir/tmp"
genomic_dir="$output_dir/GENOMIC"
mkdir -p "$tmp_dir" "$genomic_dir" || { echo "Error creating directories"; exit 1; }

cleanup() {
  if [ -d "$tmp_dir" ]; then
    if [ -z "$(ls -A "$tmp_dir")" ]; then
      rm -r "$tmp_dir" || { echo "Error removing temporary directory: $tmp_dir"; exit 1; }
    else
      echo "Temporary directory not empty, skipping deletion"
    fi
  fi
}

process_filename() {
    awk 'BEGIN { FS="\t"; OFS="\t" } {
    # Remove version number of Assembly Accession, or $1
    split($1, arr, ".")
    var1 = arr[1]
    # Remove GCA_ GCF_
    split(var1, nodb, "_")
    var4 = nodb[2]
    # Take only first 2 words in Organism Name y eso equivale a genero y especie? and replace spaces with '-'
    split($3, words, " ")
    var2 = words[1] "-" words[2]
    # Remove non-alphanumeric characters from $5 and replace spaces with '-'
    gsub(/ /, "-", $5)
    gsub(/[^a-zA-Z0-9\-]/, "", $5)
    # Remove consecutive "-" in $5
    gsub(/-+/, "-", $5)
    var3 = $5
    # Output to the following variables: accession accession_name filename
    print $1,var1, var1"_"var2"_"var3, var4
    }'
}

remove_redundant_GCA() {
  awk 'BEGIN { FS="\t"; OFS="\t" } 
{
    # Store the relevant fields
    key = $4
    value = $0

    # Check if the key already exists in the array
    if (key in data) {
        # If it exists and the current line starts with "GCF_", overwrite the other 
        if ($1 ~ /^GCF_/) {
            data[key] = value
        }
    } else {
        # If it does not exist, add it to the array
        data[key] = value
    }
}

# After processing all lines, print the results
END {
    for (key in data) {
        print data[key]
    }
}'
}

remove_column_4() {
  awk 'BEGIN { FS="\t"; OFS=" " } {
    print $1,$2,$3
}'
}


download_and_unzip() {
    # Shadowing redundante sobre todo para saber mas o menos cual es el input de esta función
    local accession=$accession
    local accession_name=$accession_name
    local filename=$filename
    # Cosas que no mutna como api_key si pueden quedar por fuera pues
    local filepath="$zip_dir/$accession_name"
    local complete_zip_path="$filepath/$accession_name.zip"
    # Descarga de archivos
    
    # Create directory for downloaded files
    mkdir -p "$filepath" || { echo "Error creating directory: $filepath"; exit 1; }
    
    
    
    # Download genome using 'datasets' (assuming proper installation)
    if [ "$num_process" -eq 3 ]; then
        datasets download genome accession "$accession" --filename "$complete_zip_path" --no-progressbar # || { echo "Error downloading genome: $accession"; exit 1; }
    else
        datasets download genome accession "$accession" --filename "$complete_zip_path" --api-key "$api_key" --no-progressbar # || { echo "Error downloading genome: $accession"; exit 1; }
    fi
    
    # Unzip genome
    archive_file="ncbi_dataset/data/$accession"
    searchpath="$filepath/$archive_file"
    unzip -oq "$complete_zip_path" "$archive_file""/GC*_genomic.fna" -d "$filepath"
    extracted=$(find "$searchpath" -name "*" -type f)
    extension="${extracted##*.}"
    mmv -d -o  "$filepath/$archive_file/"* "$genomic_dir/$filename.$extension" || { echo "Error moving files"; exit 1; }
    echo "Descargado en""$genomic_dir""/""$filename"".""$extension"""
    #rm -r $filepath
}

# Convención:
# accession_genero-especie_infraespecific-name.zip

tail -n +2 "$input_file" |
head -n +40 |
process_filename |
remove_redundant_GCA |
remove_column_4|
less
exit 0
while read -r accession accession_name filename ; do
    # Start download in the background
    
    download_and_unzip &
    
    # Limit the number of concurrent jobs
    if [[ $(jobs -r -p | wc -l) -ge $num_process ]]; then
        wait -n
    fi
    
done
# Wait for all background jobs to finish
wait

cleanup 