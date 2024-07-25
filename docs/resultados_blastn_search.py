# %%

from typing import Iterable, Iterator
import os
from pathlib import Path
from time import perf_counter
import xlsxwriter

# %%
here = os.getcwd()
File_lines = Iterable[tuple[str]]
Files = Iterable[tuple[str, File_lines]]
Folders = list[tuple[str, Files]]

# %%


def is_out(file: str) -> bool:
    extension = os.path.splitext(file)[1]
    if extension == ".out":
        return True
    else:
        return False


# %%
def get_out_folders(cwd: str):
    """Busca en el directorio y los subdirectorios"""
    dirs: Iterator[tuple[str, list, list]] = os.walk(cwd)

    for folder_path, sub_dirs, files in dirs:
        out_files = list(filter(is_out, files))
        if out_files:
            yield folder_path, out_files


# %%


def read_out_file(file_path: str) -> File_lines:
    """Extrae los resultados de un .out"""
    with open(file_path, "r") as file:
        out_lines: File_lines = [tuple(line.split()) for line in file.readlines()]
        # tuple or list?????
    return out_lines


# %%


def read_out_files(cwd: str) -> Folders:
    """Lee la carpeta que script y toda subcarpeta en busca de archivos .out

    Solo se retornan las carpetas y archivos que no estén vacíos
    """
    print("Trabajando desde...", cwd)
    folders = get_out_folders(cwd)
    out_files = []
    for folder_path, files in folders:
        data = [
            (file, read_out_file(os.path.join(folder_path, file))) for file in files
        ]
        out_files.append((Path(folder_path).parts[-1].upper(), data))
    return out_files


# %%


def write2xlsx(results: Folders, name: str) -> int:
    """Escribe los resultados a un xlsx con el nombre dado"""
    if not results:
        print("sin resultados")
        return 0

    # Create an new Excel file and add a worksheet.
    workbook = xlsxwriter.Workbook(name + ".xlsx", {"constant_memory": True})
    worksheet = workbook.add_worksheet("Resultados")

    # Add a bold format to use to highlight cells.
    bold = workbook.add_format({"bold": True})

    row, col = 0, 0
    for folder in results:
        worksheet.write_row(
            row,
            col,
            [
                folder[0],
                "",
                "Per. Ident",
                "Longitud",
                "Mismatch",
                "Gap Open",
                "Q Start",
                "Q end",
                "Start",
                "S end",
                "E-Value",
                "Bitscore",
            ],
            bold,
        )
        files = folder[1]
        row += 1
        for file in files:
            lines = file[1]
            for file_row in lines:
                worksheet.write_row(row, col, file_row)
                row += 1
            # row+=1
        row += 5
    workbook.close()
    return row


# %%
def main():
    here = os.getcwd()
    i = perf_counter()
    dirs = read_out_files(here)
    f = perf_counter()

    print("Tiempo en leer los archivo(s): ", f - i)
    i = perf_counter()
    rows = write2xlsx(dirs, "Resultados_blastn")
    f = perf_counter()
    print(f"Tiempo en escribir los archivos en {rows} líneas: ", f - i)


if "__main__" == __name__:
    main()
