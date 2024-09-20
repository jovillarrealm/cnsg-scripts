#!/bin/bash

print_help() {
    echo ""
    echo "Usage: $0 -i <taxon> [-o <directorio_output>] [-a path/to/api/key/file]"
    echo ""
    echo ""
    echo ""
    echo "This script assumes 'datasets' and 'dataformat' are in PATH"
    echo "date format is '%d-%m-%Y'"
    echo "This script uses ./summary_downloader and ./tsv_downloader.sh"
    echo ""
    echo ""
    
}

if [[ $# -lt 2 ]]; then
    print_help
    exit 1
fi

output_dir="./"
while getopts ":h:i:o:a:" opt; do
    case "${opt}" in
        i)
            taxon="${OPTARG}"
        ;;
        o)
            output_dir=$(realpath "${OPTARG}")"/"
        ;;
        a)
            api_key_file="${OPTARG}"
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

# When is this running, for traceability
today="$(date +'%d-%m-%Y')"


# If the summary already ran before, skip it 
download_file="$output_dir""$taxon""$today"".tsv"
if [ ! -f "$download_file" ];then
    ./summary_downloader.sh -i "$taxon" -o "$output_dir" -a "$api_key_file"
fi

# This check if each file is already downloaded is if its already not there
./tsv_datasets_downloader.sh -i "$download_file" -o "$output_dir" -a "$api_key_file" -p "GCA"
echo "** FINISHED **"

# Calculate stats if they don´t already exist
stats_file="$output_dir""$taxon""$today"".stats.csv"

# Make the file if it does not already exist
if [ ! -f "$stats_file" ];then
    echo "filename;assembly_length;number_of_sequences;average_length;largest_contig;shortest_contig;N50;GC_percentage;total_N;N_percentage" > "$stats_file"
fi

if [ "$(wc -l "$stats_file" | cut -d " " -f 1)" -gt 1 ]; then
    echo "Stats file is not empty"
else
    genomic_dir="$output_dir""GENOMIC/"
    find "$genomic_dir" -type f -print0 | xargs -0 -I {} -P  "$(nproc)" count-fasta-rs -c "$stats_file"  {}
#find "$genomic_dir" -type f -exec count-fasta-rs -c "$stats_file"  {} \;
#find "$genomic_dir" -type f -exec count-fasta-rs {} \;
fi
