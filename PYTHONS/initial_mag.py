import os
from pymatgen.io.vasp import Outcar, Poscar, Incar


def initial_magmom(drct):
    structure = Poscar.from_file("POSCAR").structure
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

initial_magmom(".")
