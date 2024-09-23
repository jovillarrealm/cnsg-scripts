#!/bin/bash

print_help() {
    echo ""
    echo "Uso: $0 [-o path/for/results] [-t numero de procesos] [-d  para borrar tmp FIXME]"
    echo ""
    echo "Este programa se llama desde el directorio GENOMIC para no tener que lidiar con paths en los archivos de output "
    echo "Llama a fastani con los threads especficados, por alguna razón parece funcionar mejor sin multithreading"
    echo ""
    echo "Ejemplo de correr en un solo hilo:"
    echo "../program-tester.sh -o ../ptester/ -t 1"
    echo "Ejemplo de probador de hilos:"
    echo "seq 1 8 | xargs -I {}  ../program-tester.sh -o ../results/threads/ptester/ -t {}"
    echo "seq 8 -1 1 | xargs -I {}  ../program-tester.sh -o ../results/threads/ptester/ -t {}"
    echo ""
    echo ""
}

cleanup() {
    if [[ $delete_tmp ]]
    then
        rm -r "$tmp_dir"
    fi
}


function extraer_time(){
    
    tail -n 23 "$out_file" > "$tmp_dir"tmpfile && mv "$tmp_dir"tmpfile "$out_file"
    local user_time
    user_time=$(awk 'BEGIN { FS=": "; OFS=" " } NR == 2 {print $2}' "$out_file")
    local mrss
    mrss=$(awk 'BEGIN { FS=": "; OFS=" " } NR == 10 {print $2}' "$out_file")
    echo "$user_time"';'"$mrss"';'"$threads"';'"$(( elements[i] * elements[j] ))"';'"${elements[i]}x${elements[j]}" >> "$out_dir""$resource_file_name"
}

if [[ $# -lt 1 ]]; then
    print_help
    exit 1
fi

delete_tmp=false
while getopts "h:d:o:t:" opt; do
    case "${opt}" in
        h)
            print_help
            exit 0
        ;;
        d)
            delete_tmp=true
        ;;
        o)
            out_dir=$(realpath "${OPTARG}")"/"
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
            output_name="test${elements[i]}x${elements[j]}.tsv"
            head -n "${elements[i]}" "$tmp_dir""$find_file" | tee "$tmp_dir"ql"${elements[i]}".txt
            tail -n "${elements[j]}" "$tmp_dir""$find_file" | tee "$tmp_dir"rl"${elements[j]}".txt
            #echo "$query_data"
            #echo XXXXXXXXXXX
            #echo "$reference_data"
            out_file="$out_dir"time"${elements[i]}"x"${elements[j]}".txt
            ## fastANI a veces se llama fastANI cuando se compila o descarga, pero fastani en conda :/
            # Esto maneja esos casos
            /usr/bin/time -v fastani --ql "$tmp_dir"ql"${elements[i]}".txt --rl "$tmp_dir"rl"${elements[j]}".txt -t "$threads" -o "$out_dir""$output_name" 2> "$out_file" 1> /dev/null ||
            /usr/bin/time -v fastANI --ql "$tmp_dir"ql"${elements[i]}".txt --rl "$tmp_dir"rl"${elements[j]}".txt -t "$threads" -o "$out_dir""$output_name" 2> "$out_file" 1> /dev/null
            extraer_time
        done
    done
}

resource_file_name="recs.csv"

tmp_dir="$out_dir""tmp/"
find_file="tmpaths.txt"
mkdir -p "$out_dir" "$tmp_dir"

if [[ -f "$out_dir""$resource_file_name" ]] 
then 
    echo "Preexisting recs file, appending..."
else 
    echo "user_time;mrss;threads;comparisons_number;comparisons" >> "$out_dir""$resource_file_name"

fi
# Encuentra los archivos, asumiendo que el archivo se corre con pwd en GENOMIC y los guarda a un archivo
find "." -name "GC*.fna" | tee "$tmp_dir""$find_file"

elements=(1 10)
permutations "${elements[@]}"

cleanup
echo "Listo!"
