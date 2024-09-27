import os
import csv
from scipy.stats import spearmanr
import pandas as pd
import numpy as np
import pwlf
import matplotlib.pyplot as plt


def extract_code(field: str) -> str | None:
    GC_len = 13
    if field.startswith("GC"):
        code = field[:GC_len]
        return code


def extract_gc(field: str) -> str | None:
    GC_len = 13
    index = field.find("GC")
    if index != -1:
        code = field[index : index + GC_len]
        return code


def read_mummer_data(path):
    mummer_data: dict[tuple[str, ...], tuple[float, float, int]] = dict()
    unhandled: dict[frozenset[str], tuple[float, float, int]] = dict()
    with open(path, "r") as mummmer_file:
        for line in mummmer_file:
            if "AvgIdentity" in line:
                continue
            file1, file2, aligned_bases, AI, SNPs = line.split(",")
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                key_thing: tuple[str, ...] = tuple(sorted([code1, code2]))
                mummer_data[key_thing] = (
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


def read_mummer_extracts(path):
    mummer_data: dict[tuple[str, ...], tuple[float, float, int]] = dict()
    unhandled: dict[frozenset[str], tuple[float, float, int]] = dict()
    with open(path, "r") as mummmer_file:
        for line in mummmer_file:
            if "AvgIdentity" in line:
                continue
            file1, file2, AI, aligned_bases, SNPs = line.split(";")
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                key_thing: tuple[str, ...] = tuple(sorted([code1, code2]))
                mummer_data[key_thing] = (
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
    fastani_data: dict[tuple[str, ...], tuple[float, int, int]] = dict()
    unhandled: dict[frozenset[str], tuple[float, int, int]] = dict()
    for file in os.listdir(fastani_path):
        if file.endswith("txt"):
            with open(fastani_path + file, "r") as fastani_file:
                for line in fastani_file:
                    file1, file2, ANI, mappings, total_fragments = line.split("\t")
                    code1 = extract_code(file1)
                    code2 = extract_code(file2)
                    if code1 is not None and code2 is not None:
                        key_thing: tuple[str, ...] = tuple(sorted([code1, code2]))
                        fastani_data[key_thing] = (
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
    unhandled = dict()
    with open(path, "r") as hyper_gen_file:
        for line in hyper_gen_file:
            file1, file2, ANI = line.split(";")
            code1 = extract_gc(file1)
            code2 = extract_gc(file2)
            if code1 is not None and code2 is not None:
                key_thing: tuple[str, ...] = tuple(sorted([code1, code2]))
                hypergen_data[key_thing] = float(ANI)
            else:
                unhandled[(code1, code2)] = float(ANI)
    return hypergen_data, unhandled


def read_hypergen_extracts(path):
    hypergen_data: dict[tuple[str, ...], float] = dict()
    unhandled = dict()
    with open(path, "r") as hyper_gen_file:
        for line in hyper_gen_file:
            file1, file2, ANI = line.split(";")
            code1 = extract_gc(file1)
            code2 = extract_gc(file2)
            if code1 is not None and code2 is not None:
                key_thing: tuple[str, ...] = tuple(sorted([code1, code2]))
                hypergen_data[key_thing] = float(ANI)
            else:
                unhandled[(code1, code2)] = float(ANI)
    return hypergen_data, unhandled


# Bases alineadas mummer %


def read_fastani_extracts(fastani_path):
    fastani_data: dict[tuple[str, ...], tuple[float, int, int]] = dict()
    unhandled = dict()
    with open(fastani_path, "r") as fastani_file:
        for line in fastani_file:
            file1, file2, ANI, mappings, total_fragments = line.split(";")
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                key_thing: tuple[str, ...] = tuple(sorted([code1, code2]))
                fastani_data[key_thing] = (
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


def main():
    # mummer = pd.read_csv(
    #    "error_compare/mummer.csv",
    #    names=["file1", "file2", "AI", "aligned_bases", "SNPs"],
    #    sep=";",
    # )
    # print("p-value debería ser menor que 0.05")
    # print(mummer.dtypes)
    # print(mummer.head())
    # spearman_tests(mummer, "AI", "aligned_bases", "AI vs aligned bases")
    # spearman_tests(mummer, "AI", "SNPs", "AI vs SNPs")
    #
    # fastani = pd.read_csv(
    #    "error_compare/fastani.csv",
    #    names=["file1", "file2", "ANI", "mappings", "total_fragments"],
    #    sep=";",
    # )
    # print(fastani.dtypes)
    # print(fastani.head())
    # spearman_tests(fastani, "ANI", "mappings", "ANI vs mappings")
    # spearman_tests(fastani, "ANI", "total_fragments", "ANI vs total_fragments")
    # fastani_results = pd.read_csv(
    #    "error_compare/results.csv",
    #    names=["file1", "file2", "AI_mummer", "fastani_mummer", "Error"],
    #    sep=";",
    # )
    # hypergen = pd.read_csv(
    #    "error_compare/hypergen.csv",
    #    names=["file1", "file2", "ANI"],
    #    sep=";",
    # )
    results: pd.DataFrame = pd.read_csv(
        "error_compare/results3.csv",
        names=[
            "file1",
            "file2",
            "AI_mummer",
            "Aligned_bases_mummer",
            "ANI_fastani",
            "Error_fastani",
            "ANI_hypergen",
            "Error_hypergen",
        ],
        sep=";",
    )
    stat_tests(results, "Aligned_bases_mummer", "AI_mummer", "Aligned bases vs AI mummer")
    stat_tests(results, "AI_mummer", "Error_fastani", "AI_mummer vs Error fastani")
    stat_tests(results, "AI_mummer", "ANI_fastani", "AI_mummer vs fastani")
    stat_tests(results, "AI_mummer", "Error_hypergen", "AI_mummer vs Error_hypergen")
    stat_tests(results, "AI_mummer", "ANI_hypergen", "AI_mummer vs hypergen")
    stat_tests(
        results, "Error_fastani", "Error_hypergen", "Error_fastani vs Error_hypergen"
    )

    print(f"fastani max e: {results["Error_fastani"].max()}")
    print(f"hypergen max e {results["Error_hypergen"].max()}")
    print(f"fastani median e: {results["Error_fastani"].median()}")
    print(f"hypergen median e {results["Error_hypergen"].median()}")
    print(f"fastani mean e: {results["Error_fastani"].mean()}")
    print(f"hypergen mean e {results["Error_hypergen"].mean()}")
    print(f"fastani std e: {results["Error_fastani"].std()}")
    print(f"hypergen std e {results["Error_hypergen"].std()}")


def write_2_csv(data_dict: dict[tuple[str, ...], tuple[float, float, int]], title):
    with open(title, "x") as f:
        paperback_writer = csv.writer(f, delimiter=";")
        for thing in data_dict.items():
            tup, froset = thing
            code1, code2 = tup
            if isinstance(froset, tuple):
                if len(froset) == 3:
                    v1, v2, v3 = froset
                    paperback_writer.writerow((code1, code2, v1, v2, v3))
                elif len(froset) == 2:
                    v1, v2 = froset
                    paperback_writer.writerow((code1, code2, v1, v2))
                    print(froset)
                elif len(froset) == 1:
                    v1 = froset
                    paperback_writer.writerow((code1, code2, v1))
                    print(froset)
            elif isinstance(froset, float):
                v1 = froset
                paperback_writer.writerow((code1, code2, v1))


def stat_tests(data: pd.DataFrame, c1: str, c2: str, title: str):
    s1: pd.Series = data[c1]
    s2: pd.Series = data[c2]
    print(title)
    print(data.head())
    non_zero, pval_non_zero = spearmanr(
        s1, s2, alternative="two-sided", nan_policy="omit"
    )
    print(
        f"Pearson: {np.corrcoef(data[c1], data[c2])[0,1]}, R^2: {np.corrcoef(data[c1], data[c2])[0,1]**2}"
    )
    negative, pval_less = spearmanr(s1, s2, alternative="less", nan_policy="omit")
    positive, pval_greater = spearmanr(s1, s2, alternative="greater", nan_policy="omit")

    print(f"Slope: SCC {non_zero}")
    print(f"Is there any correlation? p-value={pval_non_zero}")
    print(f"Negative correlation? p-value={pval_less}")
    print(f"Positive correlation? p-value={pval_greater}")
    x = data[c1].values
    y = data[c2].values
    the_pwlf = pwlf.PiecewiseLinFit(x, y)
    breakpoints = the_pwlf.fit(2)
    if the_pwlf.slopes is None:
        return
    x_hat = np.linspace(min(x), max(x), num=100)
    y_hat = the_pwlf.predict(x_hat)
    # Step 5: Visualize the piecewise linear model with breakpoints
    plt.scatter(x, y, color="blue", label="Original Data")
    plt.plot(
        x_hat,
        y_hat,
        color="red",
        label=f"Slope 1:{the_pwlf.slopes[0]:.2f} Slope 2: {the_pwlf.slopes[1]:.2f}",
    )
    if breakpoints is not None:
        plt.axvline(
            x=breakpoints[1],
            color="green",
            linestyle="--",
            label=f"Breakpoint: {breakpoints[1]:.2f}",
        )
    plt.xlabel(c1)
    plt.ylabel(c2)
    plt.title(title)
    plt.legend()
    # plt.show()
    plt.savefig(title + ".png")
    plt.clf()


def merger(mummer: dict, fastani: dict, hypergen: dict):
    merge = dict()
    for key in mummer.keys():
        if key in fastani and key in hypergen:
            hypergen_ani = hypergen[key]
            mummer_ai = mummer[key][0]
            mummer_aligned_bases = mummer[key][1]
            fastani_ani = fastani[key][0]
            hypergen_ani = hypergen[key]
            merge[key] = (
                mummer_ai,
                mummer_aligned_bases,
                fastani_ani,
                mummer_ai - fastani_ani,
                hypergen_ani,
                mummer_ai - hypergen_ani,
            )

    return merge


def write_results_csv(
    data_dict: dict[tuple[str, ...], tuple[float, float, float, float, float, float]],
):
    with open("results5.csv", "x") as f:
        paperback_writer = csv.writer(f, delimiter=";")
        for thing in data_dict.items():
            tup, anis = thing
            code1, code2 = tup
            v1, v2, v3, v4, v5, v6 = anis
            paperback_writer.writerow((code1, code2, v1, v2, v3, v4, v5, v6))


def extracter():
    mummer_path = "error_compare/mummer.csv"
    print("reading mummer")
    
    mummer, unhandled_mummer = read_mummer_extracts(mummer_path)

    print("reading fastani")
    fastani_extracts_path = (
        "error_compare/fastani_extracts.csv"
    )
    fastani_extracts_data, unhandled = read_fastani_extracts(fastani_extracts_path)

    print("reading hypergen")
    hypergen_file_path = "error_compare/hypergen.csv"
    hypergen_data, unhandled = read_hypergen_data(hypergen_file_path)
    print("merging")
    print(unhandled)
    merge = merger(mummer, fastani_extracts_data, hypergen_data)
    print("writing results")
    write_results_csv(merge)



main()
