#!/bin/bash

print_help() {
    echo ""
    echo "Usage: $0 -i <taxon> [-o <directorio_output>] [-a path/to/api/key/file] [-p prefered prefix]"
    echo ""
    echo ""
    echo "This script assumes 'datasets' 'dataformat' 'tsv_downloader.sh' 'summary_downloader.sh' and 'count-fasta-rs' are in PATH"
    echo "date format is '%d-%m-%Y'"
    echo "You should have an API key if possible"
    echo "This script uses ./summary_downloader and ./tsv_downloader.sh"
    echo ""
}

if [[ $# -lt 2 ]]; then
    print_help
    exit 1
fi

# Make a directory filled with hardlinks to
make_hardlinks() {
    ref_seq_dir="$output_dir""GENOMIC_ref_seq/"
    mkdir -p "$ref_seq_dir"
    find "$genomic_dir" -name "GCF_*" -exec ln -fi {} "$ref_seq_dir" \;
    # Check if the directory exists
    if [[ -d "$ref_seq_dir" ]]; then
        # Check if the directory is empty
        if [[ -z $(ls -A "$ref_seq_dir") ]]; then
            echo "Directory is empty. No RefSeq Secuences found."
            rm -r "$ref_seq_dir"
        fi
    else
        echo "**** ERROR: no RefSeq directory was created"
    fi
}

output_dir="./"
prefix="GCF"
while getopts ":h:i:o:a:p:" opt; do
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

# When is this running, for traceability
today="$(date +'%d-%m-%Y')"

echo
echo
echo "** STARTING SUMMARY DOWNLOAD **"
start_time=$(date +%s)
# If the summary already ran before, skip it
download_file="$output_dir""$taxon""_""$today"".tsv"
if [ ! -f "$download_file" ];then
    if [ -z ${api_key_file+x} ]; then
        summary_downloader.sh -i "$taxon" -o "$output_dir"
        echo "API KEY FILE NOT SET, PLEASE GET ONE FOR FASTER AND BETTER TRANSFERS"
    else
        summary_downloader.sh -i "$taxon" -o "$output_dir" -a "$api_key_file"
    fi
    
else
    echo "Summary for $today exists"
fi
echo "** DONE **"
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "Took $elapsed_time seconds"
echo

# This check if each file in the summary is already downloaded is if its not already not there
echo
echo
echo "** STARTING DOWNLOADS **"
start_time=$(date +%s)
if [ -z ${api_key_file+x} ]; then
    echo "API KEY FILE NOT SET, PLEASE GET ONE FOR FASTER AND BETTER TRANSFERS"
    tsv_datasets_downloader.sh -i "$download_file" -o "$output_dir" -p "$prefix"
else
    tsv_datasets_downloader.sh -i "$download_file" -o "$output_dir" -a "$api_key_file" -p "$prefix"
fi
rm -fr "$output_dir""tmp/"
echo
echo "** DONE **"
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "Took $elapsed_time seconds"
echo


echo
echo "** STARTING SEGREGATION AND SECUENCE ANALYSIS **"
start_time=$(date +%s)
# Make hardlinks
genomic_dir="$output_dir""GENOMIC/"
make_hardlinks
echo "Hardlinks made"


# Stats if they don´t already exist
stats_file="$output_dir""$taxon""_""$today""_stats.csv"
stats_refseq_file="$ref_seq_dir""$taxon""_""$today""_refseq_stats.csv"
num_process="$(nproc)"
num_process="$((num_process / 2))"


# Make the file if it does not already exist
if [ ! -f "$stats_file" ];then
    echo "filename;assembly_length;number_of_sequences;average_length;largest_contig;shortest_contig;N50;GC_percentage;total_N;N_percentage" > "$stats_file"
fi


if [ "$(wc -l "$stats_file" | cut -d " " -f 1)" -gt 1 ]; then
    echo "Stats file already exists"
else
    echo "Analyzing secuences"
    find "$genomic_dir" -type f -print0 | xargs -0 -I {} -P  "$num_process" count-fasta-rs -c "$stats_file"  {}
fi


if [[ -d "$ref_seq_dir" ]]; then
    if [ ! -f "$stats_refseq_file" ];then
        echo "filename;assembly_length;number_of_sequences;average_length;largest_contig;shortest_contig;N50;GC_percentage;total_N;N_percentage" > "$stats_refseq_file"
    fi
    if [ "$(wc -l "$stats_refseq_file" | cut -d " " -f 1)" -gt 1 ]; then
        echo "RefSeq Stats file already exists"
    else
        echo "Analyzing Refseq secuences"
        find "$ref_seq_dir" -type f -print0 | xargs -0 -I {} -P  "$num_process" count-fasta-rs -c "$stats_refseq_file"  {}
    fi
fi
echo "** DONE **"
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "Took $elapsed_time seconds"
echo
echo


