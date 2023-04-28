# %%

from itertools import chain
from typing import Iterator
import os
from pathlib import Path
from time import perf_counter

# %%
here = os.getcwd()

# %%


def is_out(file: str) -> bool:
    extension = os.path.splitext(file)[1]
    if extension == ".out":
        return True
    else:
        return False


# %%
def get_out_folders(cwd: str) -> list[tuple[str, list[str]]]:
    """Busca en el directorio y los subdirectorios"""
    dirs: Iterator[tuple[str, list, list]] = os.walk(cwd)
    out_folders = []
    for folder in dirs:
        folder_path, sub_dirs, files = folder
        out_files = list(filter(is_out, files))
        if out_files:
            out_folders.append((folder_path, out_files))
    return out_folders


# %%


def read_out_file(file_path: str) -> list[list[str]]:
    """Extrae los resultados de un .out"""
    lines: list[list[str]] = []
    with open(file_path, "r") as out:
        for line in out.readlines():
            lines.append(line.split())
    return lines


# %%


def read_out_files(cwd: str) -> list[tuple[str, tuple[str, list[list[str]]]]]:
    """Lee la carpeta que script y toda subcarpeta en busca de archivos .out

    Solo se retornan las carpetas y archivos que no estén vacíos
    here es desde se va a empezar a mirar"""
    print("Trabajando desde...", cwd)
    folders = get_out_folders(cwd)
    out_lines: list[tuple] = []
    for folder in folders:
        path, files = Path(folder[0]), folder[1]
        db = path.parts[-1].upper()

        folder_results = []
        for file in files:
            file_lines: list[list[str]] = []
            for line in read_out_file(os.path.join(path, file)):
                file_lines.append(line)
            if file_lines:
                file_results: tuple[str, list] = (file, file_lines)
                folder_results.append(file_results)

        if folder_results:
            out_lines.append((db, folder_results))
    return out_lines


# %%

# def write2xlsx(results:list[tuple[str,tuple[str, list[list[str]]]]], name: str):


def write2xlsx(results, name: str):
    """Escribe los resultados a un xlsx con el nombre dado"""
    if not results:
        print("sin resultados")
        return
    import xlsxwriter

    # Create an new Excel file and add a worksheet.
    workbook = xlsxwriter.Workbook(name + ".xlsx", {'constant_memory':True})
    worksheet = workbook.add_worksheet("Resultados")

    # Add a bold format to use to highlight cells.
    bold = workbook.add_format({"bold": True})

    row, col= 0,0
    for folder in results:
        worksheet.write_row(row, col, 
            [folder[0], "", "Per. Ident",	"Longitud",	"Mismatch",
            "Gap Open",	"Q Start",	"Q end",	"Start",	"S end",	"E-Value",	"Bitscore"],
            bold
        )
        files = folder[1]
        row+=1
        for file in files:
            lines = file[1]
            for file_row in lines:
                worksheet.write_row(row,col,file_row)
                row +=1
            #row+=1
        row +=5

    


# %%
def main():
    here = os.getcwd()
    i = perf_counter()
    dirs = read_out_files(here)
    f = perf_counter()

    print("Tiempo en leer los archivos: ", f - i)
    i = perf_counter()
    write2xlsx(dirs, "Resultados_blastn")
    f = perf_counter()
    print("Tiempo en escribir los archivos: ", f - i)


if "__main__" == __name__:
    main()
