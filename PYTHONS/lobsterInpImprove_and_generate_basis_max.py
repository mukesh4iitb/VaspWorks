#!/mnt/ufs18/rs-028/barone/python3.11.3/bin/python3

##### written by Dr. Mukesh Singh ###
import os
import glob
import re
import shutil
import subprocess


def improve_lobsterin_n():
    if os.path.isfile("DOSCAR"):
        print("Using DOSCAR")
        with open("DOSCAR", 'r') as f:
            f.readline()
            f.readline()
            f.readline()
            f.readline()
            f.readline()
            line=f.readline().split()
            Emax, Emin, Ef = float(line[0]), float(line[1]), float(line[-2])
            Emax = round(Emax-Ef+2, 2)
            Emin = round(Emin-Ef-2, 2)


        # Pattern to match files
        file_list = sorted(glob.glob("lobsterin.lobsterpy-*"))
        
        for file_name in file_list:
            with open(file_name, 'r') as f:
                lines = f.readlines()
        
            new_lines = []
            ## changing the COHPstartEnergy and COHPendEnergy
            for line in lines:
                if line.strip().startswith("COHPstartEnergy"):
                    new_lines.append(f"COHPstartEnergy {Emin}\n")
                elif line.strip().startswith("COHPendEnergy"):
                    new_lines.append(f"COHPendEnergy {Emax}\n")
                else:
                    new_lines.append(line)
        
            # Write the modified content back
            with open(file_name, 'w') as f:
                f.writelines(new_lines)
            print(f"updated: {file_name}")

    elif os.path.isfile("vasprun.xml"):
        print("Using vasprun.xml")

        with open('vasprun.xml') as f:
            lines = f.readlines()
        
        for line in lines:
            if "efermi" in line:
                Ef = float(line.strip().split(">")[1].split("<")[0])
            if "EMIN" in line:
                Emin = float(line.strip().split(">")[1].split("<")[0])
            if "EMAX" in line:
                Emax = float(line.strip().split(">")[1].split("<")[0])
        
        Emax = round(Emax-Ef+2, 2)
        Emin = round(Emin-Ef-2, 2)
        
        # Pattern to match files
        file_list = sorted(glob.glob("lobsterin.lobsterpy-*"))
        
        for file_name in file_list:
            with open(file_name, 'r') as f:
                lines = f.readlines()
        
            new_lines = []
            ## changing the COHPstartEnergy and COHPendEnergy
            for line in lines:
                if line.strip().startswith("COHPstartEnergy"):
                    new_lines.append(f"COHPstartEnergy {Emin}\n")
                elif line.strip().startswith("COHPendEnergy"):
                    new_lines.append(f"COHPendEnergy {Emax}\n")
                else:
                    new_lines.append(line)
        
            # Write the modified content back
            with open(file_name, 'w') as f:
                f.writelines(new_lines)
            print(f"updated: {file_name}")
    else:
        print(f"Not updated: lobsterin.lobsterpy-n")
        print("Both DOSCAR and vasprun.xml do not exit!!")



def extract_number(filename):
    match = re.search(r'-(\d+)$', filename)
    return int(match.group(1))

def creating_max_basis():
    print("Creating max basis inps for lobster calculations")
    file_list = glob.glob("lobsterin.lobsterpy-*")
    numbers = [extract_number(f) for f in file_list]
    max_number = max(numbers)

    os.makedirs("max_basis", exist_ok=True)
    shutil.copy("CONTCAR", "max_basis/POSCAR")
    shutil.copy("POTCAR", "max_basis")
    shutil.copy("KPOINTS", "max_basis")
    shutil.copy("INCAR.lobsterpy-{}".format(max_number), "max_basis/INCAR")
    shutil.copy("lobsterin.lobsterpy-{}".format(max_number), "max_basis/lobsterin")



if __name__ == "__main__":
    # creating the lobsterin.lobsterpy-n files
    subprocess.run(["lobsterpy", "create-inputs", "--overwrite"], check=True)
    ## improving the COHPstartEnergy and COHPendEnergy with DOSCAR/vasprun.xml file
    improve_lobsterin_n()
    #print("**"*20)
    ## creating maximum basis set for lobster calculation.
    creating_max_basis()
