#!/bin/bash

print_help() {
    echo ""
    echo "Usage: $0 [-i path/to/file] [-o path/to/file] [-k  input delimiter] [-l  output delimiter]"
    echo ""
    echo "Este programa convierte un archivo de valores separados por delimitador k en otro archivo de valores separado por delimitador l "
    echo ""
    echo "Ejemplo de tsv a csv:"
    echo "$0 -i ../Strepto.tsv -o ../Strepto.csv -k \"\\t\" -l \";\""
    echo ""
}

change() {
    awk -v in_del="$input_delimiter" -v out_del="$output_delimiter" '
    BEGIN { FS=in_del; OFS=out_del }
    {
    gsub(FS, OFS); print
    }
    '
}

if [[ $# -lt 2 ]]; then
    print_help
    exit 1
fi


input_delimiter="\t"
output_delimiter=";"
while getopts "i:o:k:l:h" opt; do
    case "${opt}" in
        i)
            input_file="${OPTARG}"
        ;;
        o)
            output_file="${OPTARG}"
        ;;
        k)
            input_delimiter="${OPTARG}"
        ;;
        l)
            output_delimiter="${OPTARG}"
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

change < "$input_file" > "$output_file"
