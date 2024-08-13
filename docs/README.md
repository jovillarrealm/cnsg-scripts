# Scripts bioinformática

Instalar BLAST

(Alguno de los archivos en https://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/)

    wget https://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/ncbi-blast-2.16.0+-x64-linux.tar.gz
    tar zxvpf ncbi-blast-2.16.0+-x64-linux.tar.gz

Y en ubuntu modificar el PATH con el directorio del /bin al modificar el .bashrc

    sudo apt-get install -y libgomp1

Si aparece el error tipo:
    blastn: error while loading shared libraries: libgomp.so.1: cannot open shared object file: No such file or directory
    