#print("Goining to directory of lINCAR_mag.py:")
#os.chdir(os.path.dirname(__file__))

import os
from pymatgen.io.vasp import Outcar, Poscar, Incar

def write_INCAR_mag():
    outcar = Outcar("OUTCAR")
    structure = Poscar.from_file("POSCAR").structure
    
    mag_data = outcar.magnetization
    
    magmom_list = []
    for i, site in enumerate(structure):
        if site.specie.symbol == "Fe":
            magmom_list.append(mag_data[i]["tot"])
        else:
            magmom_list.append(0.0)
    
    incar = Incar.from_file("INCAR")
    incar["MAGMOM"] = magmom_list
    incar.write_file("INCAR_mag")

def replace_magmom_from_OUTCAR(drct, dst="ZPE"):
    outcar = Outcar(os.path.join(drct, "OUTCAR"))
    structure = Poscar.from_file(os.path.join(drct,"POSCAR")).structure
    
    mag_data = outcar.magnetization
    
    magmom_list = []
    for i, site in enumerate(structure):
        if site.specie.symbol in ["Fe", "Co", "Ni"]:
            magmom_list.append(mag_data[i]["tot"])
        else:
            magmom_list.append(0.0)
    
    incar = Incar.from_file(os.path.join(drct, dst, "INCAR"))
    incar["MAGMOM"] = magmom_list
    incar["ISPIN"] = 2
    incar.write_file(os.path.join(drct, dst, "INCAR_mag"))

#drct=os.getcwd()
#with open("1.txt", "r") as f:
#    sdir = f.readline().strip()
#    while sdir:
#        replace_magmom_from_OUTCAR(os.path.join(drct, sdir))
#        sdir = f.readline().strip()

def initial_magmom(drct):
    structure = Poscar.from_file(os.path.join(drct, "POSCAR")).structure
    magmom_list = []
    for i, site in enumerate(structure):
        if site.specie.symbol=="Mn":
            magmom_list.append(5)
        elif site.specie.symbol=="Fe":
            magmom_list.append(4)
        elif site.specie.symbol=="Co":
            magmom_list.append(3)
        elif site.specie.symbol=="Ni":
            magmom_list.append(2)
        else:
            magmom_list.append(0.0)

    incar = Incar.from_file(os.path.join(drct, "INCAR"))
    incar["MAGMOM"] = magmom_list
    incar["ISPIN"] = 2
    incar.write_file(os.path.join(drct, "INCAR_mag"))
