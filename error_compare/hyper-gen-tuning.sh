#!/bin/bash
out_dir=./GENOMIC/
threads=16
while getopts "h:o:t:" opt; do
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
        \?)
            echo "Invalid option: -$OPTARG"
            print_help
            exit 1
        ;;
    esac
done

iterations=10
hv_d=4096
scaled=1500
ksize=21
iterations=0
jterations=0
kterations=0
while [[ "$hv_d" -le 1048576 ]]; do
    filename=k"$ksize"-s"$scaled"-d"$hv_d"
    hyper-gen sketch -p "$out_dir" -k "$ksize" -s "$scaled" -d "$hv_d" -o "$filename".sketch -t "$threads" -a 90
    hyper-gen dist -r "$filename".sketch -q "$filename".sketch -k "$ksize" -s "$scaled" -d "$hv_d" -o "$filename".out -t "$threads" -a 90
    
    if [[ $kterations -le 10 ]]; then
        # increase k until threshold
        ksize=$(( "$ksize" + 1 ))
        kterations=$(( "$kterations" + 1 ))
    else
        #when reached, then increase j until threadshold, resetting k each time
        jterations=$(( "$jterations" + 1 ))
        if [[ $jterations -le 10 ]]; then
            # increasing j until threshold
            scaled=$(( "$scaled" + 200 ))
            jterations=$(( "$jterations" + 1 ))
        else
            #when reached, then increase i until threadshold, resetting j each time
            iterations=$(( "$iterations" + 1))
            if [[ $iterations -le 10 ]]; then
                # increase i until condition is met
                hv_d=$(( "$hv_d" * 2 ))
                iterations=$(( "$iterations" + 1))
            else
                iterations=$(( "$iterations" + 1))
            fi
            scaled=1500
            jterations=0
        fi
        ksize=21
        kterations=0
    fi
    echo "Done $filename"
done