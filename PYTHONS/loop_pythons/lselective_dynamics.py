import os
import numpy as np
import ase.io
from ase.constraints import FixAtoms

#print("Goining to directory of lsective_dynamics.py:")
#os.chdir(os.path.dirname(__file__)) 

def creating_selective_dynamics_using_MS_M_seperation(POSCAR="POSCAR", POSCAR_Selective="POSCAR_Selective.vasp", M_atom='K', S_atom='S'):
    POS = ase.io.read(POSCAR, format='vasp')
    M_atom_indices=[]
    S_atom_indices=[]
    
    for i, atom in enumerate(POS):
        if atom.symbol == S_atom:
            S_atom_indices.append(i)
        if atom.symbol == M_atom:
            M_atom_indices.append(i)
    print("M_atom", M_atom_indices)
    print("S_atom", S_atom_indices)

    M_atom_positions = POS.positions[M_atom_indices]
    S_atom_positions = POS.positions[S_atom_indices]
    distances = np.linalg.norm(M_atom_positions - S_atom_positions, axis=1)
    seperated_M_atom = M_atom_indices[np.argmax(distances)]
    print(distances)
    print(seperated_M_atom)
    print(distances)
    selective_index = [seperated_M_atom]
    constrained_index = list(set(range(len(POS)))- set(selective_index))

    print("Vibrating/moving atoms indices:", selective_index)
    constrained = FixAtoms(constrained_index)
    POS.set_constraint(constrained)
    print("writing {}".format(POSCAR_Selective))
    ase.io.write("{}".format(POSCAR_Selective), POS, format='vasp')
    return " ".join([str(i) for i in selective_index])

#creating_selective_dynamics_using_MS_M_seperation("POSCAR", M_atom='K', S_atom='S')

#drct=os.getcwd()
#for line in ["KS_K1/","KS_K2/","KS_K3/","KS_K4/"]:
#    clean_line = line.strip()  # Remove newline or extra spaces
#    path0=os.path.join(drct, clean_line)
#    os.chdir(path0)
#    print(path0)
#    os.rename("POSCAR", "POSCAR_rlx.vasp")
#    creating_selective_dynamics_using_MS_M_seperation("POSCAR_rlx.vasp", M_atom='K', S_atom='S')
#    os.rename("POSCAR_Selective.vasp", "POSCAR")

def creating_selective_dynamics_using_symbols_or_index(POSCAR="POSCAR", POSCAR_Selective="POSCAR_Selective.vasp", symbols=None, indices=None):
    """
    1- For symbols: all moving atom's symbols should be seperated by space.
    2- For indices: all dynamical (moving) atoms in seperated by space or range seperated by '-' including lower and higher range
    """
    POS = ase.io.read(POSCAR, format='vasp')
    if symbols:
        selective_index = []
        for sym in symbols.split():
            selective_index.extend([atom.index for atom in POS if atom.symbol == sym])
        constrained_index = list(set(range(len(POS)))- set(selective_index))
    
    if indices:
        selective_index = []
        for index in indices.split():
            if "-" in index:
                lr, hr = index.split("-")  # lower range (lr) and higher range(hr)
                selective_index.extend(elem for elem in range(int(lr), int(hr)+1))
            else:
                selective_index.append(int(index))
        constrained_index = list(set(range(len(POS)))- set(selective_index))
    
    print("Vibrating/moving atoms indices:", selective_index)
    constrained = FixAtoms(constrained_index)
    POS.set_constraint(constrained)
    print("writing {}".format(POSCAR_Selective))
    ase.io.write("{}".format(POSCAR_Selective), POS, format='vasp')
    return " ".join([str(i) for i in selective_index])

#creating_selective_dynamics_using_symbols_or_index("POSCAR", symbols="Li S")
#creating_selective_dynamics_using_symbols_or_index("POSCAR", indices="1 5 10-15")

#drct=os.getcwd()
#f=open("zpe0.txt")
#lines = f.readlines()
#for line in lines:
#    clean_line = line.strip()  # Remove newline or extra spaces
#    path0=os.path.join(drct, clean_line, "ZPE")
#    os.chdir(path0)
#    print(path0)
#    os.rename("POSCAR", "POSCAR_rlx.vasp")
#    creating_selective_dynamics_POSCAR("POSCAR_rlx.vasp", symbol_index='1')
#    os.rename("POSCAR_Selective.vasp", "POSCAR")


################### main #######################
#selective_index = creating_selective_dynamics_using_MS_M_seperation("POSCAR_FN.vasp", POSCAR_Selective="POSCAR_FN_Selective.vasp", M_atom='Li', S_atom='S')
#creating_selective_dynamics_using_symbols_or_index("POSCAR_IN.vasp", POSCAR_Selective="POSCAR_IN_Selective.vasp", indices=selective_index)

