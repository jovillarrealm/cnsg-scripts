 hyper-gen -h
 1007  hyper-gen sketch -h
 1008  hyper-gen sketch -p GENOMIC/ -o strepto-fine.sketch -k 23 -s 5000 -d 16384
 1009  hyper-gen sketch -p GENOMIC/ -o strepto-fine-spec.sketch -k 50 -s 5000 -d 16384
 1010  hyper-gen dist -h
 1011  hyper-gen dist -r strepto-fine-spec.sketch -q strepto-fine-spec.sketch -k 50 -s 5000 -d 16384 -o hypergen-fine-spec.out
 1012  hyper-gen dist -r strepto-fine-spec.sketch -q strepto-fine-spec.sketch -k 50 -s 5000 -d 16384 -o hypergen-fine-spec.out -a 79
 1013  ls
 1014  hyper-gen dist -r strepto-fine-spec.sketch -q strepto-fine-spec.sketch -k 50 -s 5000 -d 16384 -o hypergen-fine-spec.out -a 79
 1015  ls
 1016  readlink -f hypergen-fine-spec.out 
 1017  hyper-gen sketch -p GENOMIC/ -o strepto-five.sketch -k 500 -s 50000 -d 131072
 1018  hyper-gen sketch -p GENOMIC/ -o strepto-five.sketch -k 255 -s 50000 -d 131072
