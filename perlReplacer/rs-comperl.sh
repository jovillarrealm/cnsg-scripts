#!/bin/bash

out_dir=./
tmp_dir=/tmp/
diffs_file="$out_dir""diffs_file"

if [[ -f "$diffs_file" ]]
then
    #echo "Preexisting recs file, appending..."
    true
else
    #echo "filename;total_length;number_of_sequences;average_length;largest_contig;shortest_contig;total_GC;GC_percentage;total_N;N_percentage" >> "$out_dir""$diffs_file"
    true
fi
tmperlfile="$out_dir""tmperlfile"
tmprsfile="$out_dir"tmpfile-rs
./count_fasta_cnsg.pl -i 100 "$@" > "$tmperlfile" 2> /dev/null
tail -n 13 "$tmperlfile" > "$tmp_dir"tmpfile && mv "$tmp_dir"tmpfile "$tmperlfile"

#/home/jorge/22julia/csng-scripts/perlReplacer/rs-count-fasta/target/release/rs-count-fasta "$1" -c "$out_dir"rs.csv >"$out_dir"tmpfile-rs
./rs-count-fasta/target/x86_64-unknown-linux-gnu/release/rs-count-fasta "$@" > "$tmprsfile"
#head -n 13 "$tmprsfile" > "$tmp_dir"tmpfile && mv "$tmp_dir"tmpfile "$tmprsfile"

diff -w "$tmperlfile" "$tmprsfile" > "$diffs_file"

lines=$(wc -l "$diffs_file" | awk '{print $1}')
if [[ "$lines" -gt 4  ]]
then
    echo "We have a problem:"
    echo "$@"
    cat "$diffs_file"
else
    #echo "filename;total_length;number_of_sequences;average_length;largest_contig;shortest_contig;total_GC;GC_percentage;total_N;N_percentage" >> "$out_dir""$diffs_file"
    true
fi