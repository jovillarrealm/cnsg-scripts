#!/bin/bash

out_dir=./
tmp_dir=/tmp/
diff_file="$out_dir""diff_file"
diffs_file="$out_dir""diffs_file"

tmperlfile="$out_dir""tmperlfile"
tmprsfile="$out_dir"tmpfile-rs

./count_fasta_cnsg.pl -i 100 "$@" > "$tmperlfile" 2> /dev/null
tail -n 13 "$tmperlfile" > "$tmp_dir"tmpfile && mv "$tmp_dir"tmpfile "$tmperlfile"

./rs-count-fasta/target/x86_64-unknown-linux-gnu/release/rs-count-fasta "$@" > "$tmprsfile"

diff -w "$tmperlfile" "$tmprsfile" > "$diff_file"

lines=$(wc -l "$diff_file" | awk '{print $1}')
if [[ "$lines" -gt 4  ]]
then
    echo "We have a problem:"
    echo "$@"
    cat "$diff_file" >> "$diffs_file"
else
    true
fi