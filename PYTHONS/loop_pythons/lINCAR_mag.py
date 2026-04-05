#print("Goining to directory of lINCAR_mag.py:")
#os.chdir(os.path.dirname(__file__))


from pymatgen.io.vasp import Outcar, Poscar, Incar
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

