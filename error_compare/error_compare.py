import os
import csv
def extract_code(field:str)->str|None:
    GC_len=13
    if field.startswith("GC"):
        code = field[:GC_len]
        return code

def read_mummer_data(path):
    mummer_data: dict[frozenset[str],frozenset[float]] = dict()
    unhandled: dict[frozenset[str],frozenset] = dict()
    with open(path,'r') as mummmer_file:
        for line in mummmer_file:
            if "AvgIdentity" in line:
                continue
            file1,file2,aligned_bases,AI,SNPs=line.split(',')
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                mummer_data[frozenset((code1,code2))] = frozenset((float(AI),float(aligned_bases),float(SNPs)))
            else:
                unhandled[frozenset((file1,file2))] = frozenset((float(AI),float(aligned_bases),float(SNPs)))
    return mummer_data, unhandled


def read_fastani_data(fastani_path):
    fastani_data:dict[frozenset[str],frozenset]= dict()
    unhandled:dict[frozenset[str],frozenset]= dict()
    for file in os.listdir(fastani_path):
        with open(fastani_path+file,'r') as fastani_file:
            for line in fastani_file:
                file1,file2,ANI,mappings,total_fragments=line.split('\t')
                code1 = extract_code(file1)
                code2 = extract_code(file2)
                if code1 is not None and code2 is not None:
                    fastani_data[frozenset((code1,code2))] = frozenset((float(ANI),float(mappings),float(total_fragments)))
                else:
                    unhandled[frozenset((file1,file2))] = frozenset((float(ANI),float(mappings),float(total_fragments)))
    return fastani_data, unhandled

def compare_datasets(d1:dict,d2:dict):
    d_MAE = dict()
    unhandled = dict()
    for key, value in d1.items():
        if key in d2:
            d2_ani = d2[key]
            mae = abs(ani-d2_ani)
            d_MAE[key]=mae
        else: 
            unhandled[key] = ani

    return d_MAE, unhandled
    


        


        

def main():
    mummer_path = "/home/users/javillamar/cnsg-scripts/Streptomces_1020_Select_USAL_TABLAfullDNADIFF.csv"
    partial_path="/home/users/jfar/temp/FastANIfiles_TXT/"
    extract_code("GCA_0000097652_Streptomyces_avermitilis_MA-4680_NBRC14893_MA-4680_")
    print("Reading the mummer file")
    mummer, unhandled_mummer =read_mummer_data(mummer_path)
    write_2_csv(mummer,"mummer.csv")
    print("Reading fastani files")
    fastani, unhandled_fastani = read_fastani_data(partial_path)
    write_2_csv(fastani,"fastani.csv")
    print("Comparing datasets")
    mae, unhandled_mae = compare_datasets(mummer,fastani)
    print("writing files")
    write_2_csv(mae,"mae.csv")
    #write_2_csv(unhandled_mummer,"unhandled_mummer.csv")
    #write_2_csv(unhandled_fastani,"unhandled_fastani.csv")
    #write_2_csv(unhandled_mae,"unhandled_mae.csv")
    



def write_2_csv(data_dict,title):
    with open(title,"x") as f:
        paperback_writer=csv.writer(f,delimiter=';')
        for tup,froset in data_dict.items():
            code1,code2=tup
            if len(froset) == 3:
                v1,v2,v3 = froset
                paperback_writer.writerow((code1,code2,v1,v2,v3))
            elif len(froset) == 2:
                v1,v2 = froset
                paperback_writer.writerow((code1,code2,v1,v2))
            elif len(froset) == 1:
                v1,v2 = froset
                paperback_writer.writerow((code1,code2,v1))
            

main()