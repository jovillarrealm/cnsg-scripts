from tabulate import tabulate
def extract_code(field:str)->str:
    GC_len=13
    if field.startswith("GC"):
        code = field[:GC_len]
        return code

def read_mummer_data(path):
    mummer_data: dict[tuple[str,str],float] = dict()
    with open(path,'r') as mummmer_file:
        for line in mummmer_file:
            file1,file2,aligned_bases,ANI,SNPs=line.split(',')
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                mummer_data[(code1,code2)] = float(ANI)
            else:
                pass
                #print("UNHANDLED:",file1,file2)
    return mummer_data

        

        
mummer_path = "/home/portatilcnsg/Desktop/JoRepos/csng-scripts/error_compare/Streptomces_1020_Select_USAL_TABLAfullDNADIFF.csv"
extract_code("GCA_0000097652_Streptomyces_avermitilis_MA-4680_NBRC14893_MA-4680_")
mummer =read_mummer_data(mummer_path)
for i in mummer.items():
    tup,ani=i
    code1,code2=tup
    print(code1, code2, ani)
