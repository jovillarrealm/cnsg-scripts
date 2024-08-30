#!/bin/bash

find GENOMIC/ -type f -exec basename {} ';'| xargs -I {}  hyper-gen sketch -p GENOMIC/{} -o SKETCH/{}