#!/bin/bash

print_help() {
    echo ""
    echo "Uso: $0 [-i tsv/input/file/path] [-o path/for/dir/GENOMIC] [-a path/to/api/key/file] [-d FIXME solo funciona con argumento de basura]"
    echo ""
    echo "Este programa asume que el 'datasets' de la ncbi está instalado y se llama con 'datasets'"
    echo "Este programa usa unzip, mmv, awk"
    echo "Primera área de mejora, pasar flags de acá a datasets"
    echo "De momento solo se maneja --api-key indirectamente"
    echo ""
    
}

if [[ $# -lt 2 ]]; then
  print_help
  exit 1
fi


cleanup() {

    if $delete_tmp; then
        echo "Borrando temporales"
        rm -r "$tmp_dir"
        # do dangerous stuff
    else 
        echo "No se borran archivos temporales"
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
    gsub(/[^a-zA-Z0-9 ]/, "", $3)
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
    print $1, $2, $3 
    }'
}


download_and_unzip() {
    # Shadowing redundante sobre todo para saber mas o menos cual es el input de esta función
    local accession=$accession
    local accession_name=$accession_name
    local filename=$filename
    # Cosas que no mutna como api_key si pueden quedar por fuera pues
    local filepath="$tmp_dir""$accession_name"
    local complete_zip_path="$filepath""$accession_name.zip"
    # Descarga de archivos
    local downloaded_path="$genomic_dir""$filename.fna"
    if [ -f "$downloaded_path" ]; then
        echo "Ya estaba descargado en $downloaded_path"
    else
        
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
        mmv -d -o  "$filepath/$archive_file/"* "$genomic_dir/$filename.$extension" # || { echo "Error moving files"; exit 1; }
        echo "Descargado en""$downloaded_path"
    fi
}

delete_tmp=false
num_process=3
while getopts ":h:d:i:o:a:" opt; do
    case "${opt}" in
        i)
            input_file="${OPTARG}"
            ;;
        o)
            output_dir="${OPTARG}"
            ;;
        a)
            echo "API Key en archivo: ""${OPTARG}"" se van a poder, máximo 10 descargas a la vez"
            api_key=$( cat "${OPTARG}" )
            num_process=10
            ;;
        d)
            delete_tmp=true
            ;;
        h)
            print_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            print_help
            exit 1
            ;;
    esac
done
echo "Archivo TSV: ""$input_file"
echo "API KEY: ""$api_key"
echo "Directorio para directorio GENOMIC: ""$output_dir"
# Create temporary and output directories
tmp_dir="$output_dir""tmp/"
genomic_dir="$output_dir""GENOMIC/"

mkdir -p "$tmp_dir" "$genomic_dir" || { echo "Error creating directories"; exit 1; }
echo "Creado" "$tmp_dir" "$genomic_dir"
# ARTIFICIAL LIMIT FOR TESTING
files_to_download=200

tail -n +2 "$input_file" |
head -n +$files_to_download |
process_filename |
remove_redundant_GCA |
remove_column_4 |
while read -r accession accession_name filename ; do
    # Start download in the background
    
    download_and_unzip &
    
    # Limit the number of concurrent jobs
    if [[ $(jobs -r -p | wc -l) -ge $num_process ]]; then
        wait
        #wait -n # FIXME: en bash <4.3 no existe wait -n entonces toca hacer que acabe un bache de descargas antes de continuar
    fi
    
done
# Wait for all background jobs to finish
wait

cleanup