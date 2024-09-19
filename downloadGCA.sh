#!/bin/bash

./summary_downloader.sh -i "$1" -o .
./tsv_datasets_downloader.sh -i "$1"".tsv" -o .