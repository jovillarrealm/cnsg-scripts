import os
import csv
def extract_code(field:str)->str|None:
    GC_len=13
    if field.startswith("GC"):
        code = field[:GC_len]
        return code

def read_mummer_data(path):
    mummer_data: dict[tuple[str,str],float] = dict()
    unhandled: dict[tuple[str,str],float] = dict()
    with open(path,'r') as mummmer_file:
        for line in mummmer_file:
            file1,file2,aligned_bases,ANI,SNPs=line.split(',')
            code1 = extract_code(file1)
            code2 = extract_code(file2)
            if code1 is not None and code2 is not None:
                mummer_data[(code1,code2)] = float(ANI)
            else:
                unhandled[(file1,file2)] = float(ANI)
    return mummer_data, unhandled

def read_fastani_data(fastani_path):
    fastani_data:dict[tuple[str,str],float]= dict()
    unhandled:dict[tuple[str,str],float]= dict()
    for file in os.listdir(fastani_path):
        print(file)
        with open(fastani_path+"file",'r') as fastani_file:
            for line in fastani_file:
                file1,file2,ANI,_,_=line.split('\t')
                code1 = extract_code(file1)
                code2 = extract_code(file2)
                if code1 is not None and code2 is not None:
                    fastani_data[(code1,code2)] = float(ANI)
                else:
                    unhandled[(file1,file2)] = float(ANI)
    return fastani_data, unhandled
        

def main():
    mummer_path = "/home/users/javillamar/cnsg-scripts/Streptomces_1020_Select_USAL_TABLAfullDNADIFF.csv"
    partial_path="/home/users/jfar/temp/FastANIfiles_TXT"
    extract_code("GCA_0000097652_Streptomyces_avermitilis_MA-4680_NBRC14893_MA-4680_")
    mummer, unhandled_mummer =read_mummer_data(mummer_path)
    fastani, unhandled_fastani = read_fastani_data(partial_path)
    write_2_csv(mummer,"mummer.csv")
    write_2_csv(fastani,"fastani.csv")
    write_2_csv(unhandled_mummer,"unhandled_mummer.csv")
    write_2_csv(unhandled_fastani,"unhandled_fastani.csv")

def write_2_csv(data_dict,title):
    with open(title,"x") as f:
        paperback_writer=csv.writer(f,delimiter=';')
        for i in data_dict.items():
            tup,ani=i
            code1,code2=tup
            paperback_writer.writerow((code1,code2,ani))
        

main()