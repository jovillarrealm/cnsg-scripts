#!/bin/bash

print_help() {
    echo ""
    echo "Uso: $0 [-i tsv/input/file/path] [-o path/for/dir/GENOMIC] [-d  para borrar tmp] [-t numero de procesos]"
    echo ""
    echo "Este programa se debería llamar desde el directorio GENOMIC para no tener que lidiar con esos paths en la "
    echo "Este programa usa unzip, mmv, awk"
    echo "Primera área de mejora, pasar flags de acá a datasets"
    echo "De momento solo se maneja --api-key indirectamente"
    echo ""
}

cleanup() {
    if [[ $delete_tmp ]]
    then
        rm -r "$tmp_dir"
    fi
}


function extraer_time(){
    tail -n 23 "$out_dir""$out_file" > "$tmp_dir""$log_name" && mv "$tmp_dir""$log_name" "$out_dir""$out_file"
    local user_time
    user_time=$(awk 'BEGIN { FS=": "; OFS=" " } NR == 2 {print $2}' "$out_dir""$out_file")
    local mrss
    mrss=$(awk 'BEGIN { FS=": "; OFS=" " } NR == 10 {print $2}' "$out_dir""$out_file")
    echo "$user_time" "$mrss" "$(( ${elements[i]} * ${elements[j]} ))" >> "$out_dir""$resource_file_name"
}



if [[ $# -lt 2 ]]; then
    print_help
    exit 1
fi

delete_tmp=false
while getopts "h:d:i:o:t:" opt; do
    case "${opt}" in
        h)
            print_help
            exit 0
        ;;
        d)
            delete_tmp=true
        ;;
        i)
            input_file="${OPTARG}"
        ;;
        o)
            out_dir="${OPTARG}"
        ;;
        t)
            threads="${OPTARG}"
        ;;
        \?)
            echo "Invalid option: -$OPTARG"
            print_help
            exit 1
        ;;
    esac
done

# Function to generate permutations
function permutations() {
    local elements=("$@")
    local n=${#elements[@]}
    
    for (( i=0; i<n; i++ )); do
        for (( j=i; j<n; j++ )); do
            echo "${elements[i]}" "${elements[j]}"
            output_name="test${elements[i]}x${elements[j]}.fastani"
            log_name="log${elements[i]}x${elements[j]}.fastani"
            query_data=$(head -n "${elements[i]}" "$tmp_dir""$find_file" | tee "$tmp_dir"ql"${elements[i]}".txt)
            reference_data=$(tail -n "${elements[j]}" "$tmp_dir""$find_file" | tee "$tmp_dir"rl"${elements[j]}".txt)
            #echo "$query_data"
            #echo XXXXXXXXXXX
            #echo "$reference_data"
            out_file="$out_dir"time"${elements[i]}"x"${elements[j]}".txt
            if [[ $( bash --version ) =~ 5.2.21 ]]
            then
                /usr/bin/time -v fastani --ql "$tmp_dir"ql"${elements[i]}".txt --rl "$tmp_dir"rl"${elements[j]}".txt -t "$threads" -o "$out_dir""$output_name" 1> "$out_dir""$log_name" 2> "$out_dir""$out_file"
            else
                /usr/bin/time -v fastANI --ql "$tmp_dir"ql"${elements[i]}".txt --rl "$tmp_dir"rl"${elements[j]}".txt -t "$threads" -o "$out_dir""$output_name" 1> "$tmp_dir""$log_name" 2> "$out_dir""$out_file"
            fi
            extraer_time
        done
    done
}

resource_file_name="recs.txt"
tmp_dir="$out_dir""tmp/"
find_file="tmpaths.txt"
mkdir -p "$out_dir" "$tmp_dir"

# Encuentra los archivos, asumiendo que el archivo se corre con pwd en GENOMIC y los guarda a un archivo
data=$(find "." -name "GC*.fna" | tee "$tmp_dir""$find_file")


echo "Run con t=$threads:" >> "$out_dir""$resource_file_name"

elements=(1 10)
permutations "${elements[@]}"

cleanup
echo "Listo!"
