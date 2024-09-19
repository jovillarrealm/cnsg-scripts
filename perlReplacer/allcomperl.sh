#!/bin/bash
sp="/-\|"
sc=0
spin() {
   printf "\b${sp:sc++:1}"
   ((sc==${#sp})) && sc=0
}
endspin() {
   printf "\r%s\n" "$@"
}

for f in $(find GENOMIC/ -type f) 
do
    echo "$f"
    xargs -n 1 ./rs-comperl.sh "$f"
done
