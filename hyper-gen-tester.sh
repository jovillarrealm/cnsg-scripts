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
        echo "Archivos temporales borrados"
    fi
}


function extraer_time(){
    
    tail -n 23 "$out_file" > "$tmp_dir"tmpfile && mv "$tmp_dir"tmpfile "$out_file"
    local user_time
    user_time=$(awk 'BEGIN { FS=": "; OFS=" " } NR == 2 {print $2}' "$out_file")
    local mrss
    mrss=$(awk 'BEGIN { FS=": "; OFS=" " } NR == 10 {print $2}' "$out_file")
    echo "$user_time"';'"$mrss"';'"$threads"';'"$(( ${elements[i]} * ${elements[j]} ))"';'"${elements[i]}x${elements[j]}" >> "$out_dir""$resource_file_name"
}

function hottogo() {
    rl_file="$tmp_dir""testrl${elements[j]}.sketch"
    ql_file="$tmp_dir""testql${elements[i]}.sketch"
    hyper-gen sketch --path "$q_dir" --out "$ql_file" -t "$threads"
    hyper-gen sketch --path "$r_dir" --out "$rl_file" -t "$threads"
    hyper-gen dist -r "$rl_file" -q "$ql_file" --out "$output_name" -t "$threads"
    echo "Done"
}

if [[ $# -lt 1 ]]; then
    print_help
    exit 1
fi

delete_tmp=false
if [[ -n "$d" ]]; then
    delete_tmp=true
    echo "Se van a borrar archivos temporales"
fi
while getopts "h:o:t:d:" opt; do
    case "${opt}" in
        h)
            print_help
            exit 0
        ;;
        o)
            out_dir=$(realpath "${OPTARG}")"/"
        ;;
        t)
            threads="${OPTARG}"
        ;;
        d)
            delete_tmp=true
            echo "Se van a borrar archivos temporales"
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
            q_dir="$q_incomplete""${elements[i]}/" 
            r_dir="$r_incomplete""${elements[j]}/" 
            mkdir -p "$q_dir" "$r_dir"
            head -n "${elements[i]}" "$tmp_dir""$find_file" | xargs -I {} ln {} -t "$q_dir" 2> /dev/null
            tail -n "${elements[j]}" "$tmp_dir""$find_file" | xargs -I {} ln {} -t "$r_dir" 2> /dev/null
            out_file="$out_dir"time"${elements[i]}"x"${elements[j]}".txt
            hottogo
            extraer_time
        done
    done
}

resource_file_name="recs.csv"
tmp_dir="$out_dir""tmp/"
q_incomplete="$tmp_dir""ql"
r_incomplete="$tmp_dir""rl"
find_file="tmpaths.txt"
mkdir -p "$out_dir" "$tmp_dir"
#cd "GENOMIC/" || (echo "No GENOMIC" && exit 1)
find "./GENOMIC/" -name "GC*.fna" | tee "$tmp_dir""$find_file"
#cd "../" || echo "No GENOMIC" || exit 
elements=(1 10 100)
permutations "${elements[@]}"


