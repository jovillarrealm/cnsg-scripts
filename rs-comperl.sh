#!/bin/bash

out_dir=./
resource_file_name="recs.csv"
if [[ -f "$out_dir""$resource_file_name" ]]
then
    echo "Preexisting recs file, appending..."
else
    echo "filename;total_length;number_of_sequences;average_length;largest_contig;shortest_contig;total_GC;GC_percentage;total_N;N_percentage" >> "$out_dir""$resource_file_name"
fi
tmperlfile="$out_dir""tmperlfile"
/home/jorge/22julia/csng-scripts/perlReplacer/count_fasta_cnsg.pl -i 100 "$1" > "$tmperlfile"
tail -n 13 "$tmperlfile" > "$tmp_dir"tmpfile && mv "$tmp_dir"tmpfile "$tmperlfile"

#/home/jorge/22julia/csng-scripts/perlReplacer/rs-count-fasta/target/release/rs-count-fasta "$1" -c "$out_dir"rs.csv >"$out_dir"tmpfile-rs
/home/jorge/22julia/csng-scripts/perlReplacer/rs-count-fasta/target/release/rs-count-fasta "$1" 100 >"$out_dir"tmpfile-rs

diff -w "$out_dir""tmperlfile" "$out_dir""tmpfile-rs" >> "$out_dir"diffs