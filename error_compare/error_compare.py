import os
import csv
from scipy.stats import spearmanr
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt


def extract_code(field: str) -> str | None:
    GC_len = 13
    if field.startswith("GC"):
        code = field[:GC_len]
        return code


def read_mummer_data(path):
    mummer_data: dict[frozenset[str], tuple[float, float, int]] = dict()
    unhandled: dict[frozenset[str], tuple[float, float, int]] = dict()
    with open(path, "r") as mummmer_file:
        for line in mummmer_file:
            if "AvgIdentity" in line:
                continue
            file1, file2, aligned_bases, AI, SNPs = line.split(",")
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                mummer_data[frozenset((code1, code2))] = (
                    float(AI),
                    float(aligned_bases),
                    int(SNPs),
                )
            else:
                unhandled[frozenset((file1, file2))] = (
                    float(AI),
                    float(aligned_bases),
                    int(SNPs),
                )
    return mummer_data, unhandled


def read_fastani_data(fastani_path):
    fastani_data: dict[frozenset[str], tuple[float, int, int]] = dict()
    unhandled: dict[frozenset[str], tuple[float, int, int]] = dict()
    for file in os.listdir(fastani_path):
        if file.endswith("txt"):
            with open(fastani_path + file, "r") as fastani_file:
                for line in fastani_file:
                    file1, file2, ANI, mappings, total_fragments = line.split("\t")
                    code1 = extract_code(file1)
                    code2 = extract_code(file2)
                    if code1 is not None and code2 is not None:
                        fastani_data[frozenset((code1, code2))] = (
                            float(ANI),
                            int(mappings),
                            int(total_fragments),
                        )
                    else:
                        unhandled[frozenset((file1, file2))] = (
                            float(ANI),
                            int(mappings),
                            int(total_fragments),
                        )
    return fastani_data, unhandled


def read_hypergen_data(path):
    hypergen_data: dict[tuple[str, ...], float] = dict()
    unhandled= dict()
    with open(path, "r") as hyper_gen_file:
        for line in hyper_gen_file:
            file1, file2, ANI= line.split("\t")
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                key_thing: tuple[str,...] = tuple(sorted([code1,code2]))
                hypergen_data[key_thing] = float(ANI)
            else:
                unhandled[(code1, code2)] = float(ANI)
    return hypergen_data, unhandled


def main():
    mummer = pd.read_csv(
        "error_compare/mummer.csv",
        names=["file1", "file2", "AI", "aligned_bases", "SNPs"],
        sep=";",
    )
    print("p-value debería ser menor que 0.05")
    print(mummer.dtypes)
    print(mummer.head())
    spearman_tests(mummer, "AI", "aligned_bases", "AI vs aligned bases")
    spearman_tests(mummer, "AI", "SNPs", "AI vs SNPs")

    fastani = pd.read_csv(
        "error_compare/fastani.csv",
        names=["file1", "file2", "ANI", "mappings", "total_fragments"],
        sep=";",
    )
    print(fastani.dtypes)
    print(fastani.head())
    spearman_tests(fastani,"ANI", "mappings", "ANI vs mappings")
    spearman_tests(fastani,"ANI", "total_fragments", "ANI vs total_fragments")
    #spearman_tests(fastani,"ANI", "AI", "ANI vs AI")


def write_2_csv(data_dict, title):
    with open(title, "x") as f:
        paperback_writer = csv.writer(f, delimiter=";")
        for tup, froset in data_dict.items():
            code1, code2 = tup
            if isinstance( froset,frozenset):
                if len(froset) == 3:
                    v1, v2, v3 = froset
                    paperback_writer.writerow((code1, code2, v1, v2, v3))
                elif len(froset) == 2:
                    v1, v2 = froset
                    paperback_writer.writerow((code1, code2, v1, v2))
                    print(froset)
                elif len(froset) == 1:
                    v1, v2 = froset
                    paperback_writer.writerow((code1, code2, v1))
                    print(froset)
            elif issubclass(float, froset):
                v1, v2 = froset
                paperback_writer.writerow((code1, code2, v1))



def spearman_tests(data, c1: str, c2: str, title: str):
    s1: pd.Series = data[c1]
    s2: pd.Series = data[c2]
    print(title)
    non_zero, pval_non_zero = spearmanr(
        s1, s2, alternative="two-sided", nan_policy="omit"
    )
    negative, pval_less = spearmanr(s1, s2, alternative="less", nan_policy="omit")
    positive, pval_greater = spearmanr(s1, s2, alternative="greater", nan_policy="omit")
    print(f"Slope: SCC {non_zero}")
    print(f"Is there any correlation? p-value={pval_non_zero}")
    print(f"Negative correlation? p-value={pval_less}")
    print(f"Positive correlation? p-value={pval_greater}")
    sns.regplot(data=data, x=c1, y=c2, line_kws=dict(color="b"))
    plt.savefig(title + ".png")


def extracter():
    #mummer_path = "/home/users/javillamar/cnsg-scripts/Streptomces_1020_Select_USAL_TABLAfullDNADIFF.csv"
    #partial_path = "/home/users/jfar/temp/FastANIfiles_TXT/"
    #mummer_path = "/home/portatilcnsg/Desktop/JoRepos/cnsg-scripts/error_compare/Streptomces_1020_Select_USAL_TABLAfullDNADIFF.csv"
    #mummer, unhandled_mummer = read_mummer_data(mummer_path)
    #write_2_csv(mummer, "mummer.csv")
    # fastani, unhandled_fastani = read_fastani_data(partial_path)
    # write_2_csv(fastani,"fastani.csv")

    # mae, unhandled_mae = compare_datasets(mummer,fastani)

    # write_2_csv(unhandled_mummer,"unhandled_mummer.csv")
    # write_2_csv(unhandled_fastani,"unhandled_fastani.csv")
    # write_2_csv(unhandled_mae,"unhandled_mae.csv")
    hypergen_file_path="./hypergen.out"
    hypergen_file_path="/home/portatilcnsg/Desktop/JoRepos/cnsg-scripts/error_compare/hypergen.out"
    hypergen_data, unhandled = read_hypergen_data(hypergen_file_path)
    #print("unhanlded:", unhandled)
    write_2_csv(hypergen_data, "hypergen.csv")

extracter()
