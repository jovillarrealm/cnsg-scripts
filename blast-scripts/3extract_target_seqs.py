import Bio.SeqIO as bio
import os


def targets_from_text_file(file_path: str) -> list[str]:
    """Del nombre de un txt con los nombres de las secuencias que vayan ser alineadas y retorna lista de los ids de las secuencias
    Se puede generalizar
    """
    with open(file_path) as target_seqs:
        targets = [seq.strip(" \n").lstrip(">")
                   for seq in target_seqs.readlines()]
    return targets


def extract_seqs(targets: list[str], carpeta: str):
    """Con una lista de ids de las secuencias hace un fasta filtrado con las secuencias para cada archivo"""
    def is_fasta(file): return ".fasta" in file
    #is_fasta = lambda file: ".fasta" in file
    fastas = filter(is_fasta, os.listdir(carpeta))
    for file in fastas:
        _extract_seq(file, targets)


def _extract_seq(file: str, targets: list[str]):
    """Hace un fasta filtrado con las secuencias de un archivo"""
    outs = []
    with open(carpeta+"/"+file) as fasta:
        for seq_record in bio.parse(fasta, "fasta"):
            if seq_record.id in targets:
                outs.append(seq_record)

    def record_len(record): return len(record)
    outs.sort(key=record_len, reverse=True)
    filtered_path = "filtered"
    if not os.path.exists(filtered_path):
        os.makedirs(filtered_path)
    if outs:
        bio.write(outs, filtered_path+"/f_"+file, "fasta")


def main(carpeta):
    extensiones = [".txt"]
    def is_text(file):
        for ext in extensiones:
            #FIXME esto no distingue entre extension y nombre de archivo normal
            if ext in file: 
                return True
        return False
    file_name = str(filter(is_text, os.listdir(carpeta)))
    targets = targets_from_text_file(carpeta+"/"+file_name)
    extract_seqs(targets, carpeta)


if "__main__" == __name__:
    carpeta = input(
"""Carpeta donde están los tejidos? 
p. ej. carpeta "tejidos" 
""")
    #carpeta = "tejidos"
    # targets from txt va a estar con un filtro en la misma carpeta?
    print(
"""Nombre del archivo de texto donde se extraen, dentro del archivo se ve:
>SeqIDejemplo1
>SeqIDejemplo2
>TRINITY_DN545_c0_g1_i14 
>TRINITY_DN545_c0_g1_i6 
>TRINITY_DN545_c0_g1_i3 
""")
    main(carpeta)
