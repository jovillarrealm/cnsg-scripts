#!/bin/bash

change() {
    awk 'BEGIN { FS="\t"; OFS="," }
{
gsub(/\t/, OFS); print
}
' 
}
change < "$1" > "eDNA-empty/file.csv"