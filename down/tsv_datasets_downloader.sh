#!/bin/bash

print_help() {
    echo ""
    echo "Usage: $0 -i tsv/input/file/path -o path/for/dir/GENOMIC [-a path/to/api/key/file] [-p preferred prefix]"
    echo ""
    echo ""
    echo ""
    echo "This script assumes 'datasets' and 'dataformat' are in PATH"
    echo "It uses unzip, awk, xargs, datasets, dataformat"
    echo ""
    echo "prefered prefix can either be GCA (default, GenBank) of GCF (RefSeq)"
    echo ""
    echo "Falta reportes de errores para añadir robustez y prevenir mal uso"
    echo "Elegir y confirmar columnas de a leer por tsv"
    echo ""
    echo ""
    
}

if [[ $# -lt 2 ]]; then
    print_help
    exit 1
fi

process_filename() {
    awk 'BEGIN { FS="\t"; OFS="\t" } {
    # Remove version number of Assembly Accession, or $1
    split($1, arr, ".")
    var1 = arr[1]
    # Remove GCA_ GCF_
    split(var1, nodb, "_")
    var4 = nodb[2]
    # Take only first 2 words in Organism Name y eso equivale a genero y especie? and replace spaces with '-'
    gsub(/[^a-zA-Z0-9 ]/, "", $2)
    split($2, words, " ")
    var2 = words[1] "-" words[2]
    # Remove non-alphanumeric characters from $3 and replace spaces with '-'
    gsub(/ /, "-", $3)
    gsub(/[^a-zA-Z0-9\-]/, "", $3)
    # Remove consecutive "-" in $3
    gsub(/-+/, "-", $3)
    var3 = $3
    # Output to the following variables: accession accession_name filename
    print $1,var1, var1"_"var2"_"var3, var4
    }'
}

keep_GCX() {
    awk -v code="$prefix" 'BEGIN { FS="\t"; OFS="\t" }
{
    # Store the relevant fields
    key = $4
    value = $1 OFS $2 OFS $3

    # Check if the key already exists in the array
    if (key in data) {
        # If it exists and the current line starts with "code_", overwrite the other
        if ($1 ~ "^" code "_") {
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



download_and_unzip() {
    # Shadowing redundante sobre todo para saber mas o menos cual es el input de esta función
    local accession="$accession"
    local accession_name="$accession_name"
    local filename="$filename"
    local filepath="$tmp_dir""$accession_name""/"
    local complete_zip_path="$filepath""$accession_name.zip"
    local downloaded_path="$genomic_dir""$filename.fna"
    # Download files
    if [ -f "$downloaded_path" ]; then
        # echo "Already in  $downloaded_path"
        return
    else
        
        # Create directory for downloaded files
        mkdir -p "$filepath" || {
            echo "Error creating directory: $filepath"
            exit 1
        }
        
        # Download genome using 'datasets' (assuming proper installation)
        if [ "$num_process" -eq 3 ]; then
            if ! datasets download genome accession "$accession" --filename "$complete_zip_path" --include genome --no-progressbar; then # || { echo "Error downloading genome: $accession"; exit 1; }
                echo "**** FAILED TO DOWNLOAD $accession , en  $complete_zip_path"
                return 1
            fi
        else
            if ! datasets download genome accession "$accession" --filename "$complete_zip_path" --include genome --api-key "$api_key" --no-progressbar; then # || { echo "Error downloading genome: $accession"; exit 1; }
                echo "**** ERROR TO DOWNLOAD $accession , en  $complete_zip_path"
                return 1
            fi
        fi
        
        # Unzip genome
        archive_file="ncbi_dataset/data/$accession"
        searchpath="$filepath""$archive_file"
        unzip -oq "$complete_zip_path" "$archive_file""/GC*_genomic.fna" -d "$filepath"
        
        # Move to desired location
        extracted=$(find "$searchpath" -name "*" -type f)
        extension="${extracted##*.}"
        if ! find "$filepath""$archive_file" -type f -print0 | xargs -0 -I {} mv -n {} "$genomic_dir""$filename.$extension"; then
            echo "**** ERROR TO MOVE contents of : " "$filepath""$archive_file/" "  in  " "$genomic_dir""$filename.$extension"
        else
            # Cleanup
            if $delete_tmp; then
                rm -r "$filepath"
            fi
        fi
    fi
}

#print_progress() {
#    downloaded_files=$(find "$genomic_dir" -type f | wc -l)
#    remaining_files=$((total_files - downloaded_files - 1))
#    echo -n "$remaining_files"
#    while [[ "$remaining_files" -gt "0" ]]; do
#        echo -n ", ""$remaining_files"
#        sleep 15
#        downloaded_files=$(find "$genomic_dir" -type f | wc -l)
#        remaining_files=$((total_files - downloaded_files - 1))
#    done
#}

# Start program
delete_tmp=true
num_process=3
prefix="GCA"
while getopts ":h:p:i:o:a:" opt; do
    case "${opt}" in
        i)
            input_file="${OPTARG}"
        ;;
        o)
            output_dir=$(realpath "${OPTARG}")"/"
        ;;
        a)
            api_key_file="${OPTARG}"
            echo "API Key en archivo: ""${api_key_file}"" se van a poder, máximo 10 descargas a la vez"
            api_key=$(cat "${OPTARG}")
            num_process=10
        ;;
        p)
            prefix="${OPTARG}"
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
echo "TSV: ""$input_file"
echo "Output directory for GENOMIC: ""$output_dir"
# Create temporary and output directories
tmp_dir="$output_dir""tmp/"
genomic_dir="$output_dir""GENOMIC/"

mkdir -p "$tmp_dir" "$genomic_dir" || {
    echo "Error creating directories"
    exit 1
}
echo "Created: " "$tmp_dir"
echo "Created: " "$genomic_dir"
echo "Preferred prefix: $prefix"

tmp_names="$tmp_dir""/tmp_names"

#total_files=$( wc -l < "$input_file" )
#echo -n "Remaining files: "
#print_progress &




tail -n +2 "$input_file" |
process_filename |
keep_GCX  > "$tmp_names"
while read -r accession accession_name filename; do
    # Start download in the background
    
    download_and_unzip &
    
    # Limit the number of concurrent jobs
    if [[ $(jobs -r -p | wc -l) -ge $num_process ]]; then
        wait
        #wait -n # en bash <4.3 no existe wait -n entonces toca hacer que acabe un bache de descargas antes de continuar
    fi
    
done < "$tmp_names"
# Wait for all background jobs to finish and probably fails on older systems when the preious wait is fullfilled because the signals get mixed
wait
