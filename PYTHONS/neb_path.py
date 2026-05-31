import os
import ase.io

def neb_path(drct=os.getcwd(), final_path=True, initial_path=False):
    neb_folders = sorted( [d for d in os.listdir(drct) if os.path.isdir(d) and len(d) == 2 and d.isdigit()])
    print("NEB folders:", " ".join(neb_folders))
    POS00 = ase.io.read("00/POSCAR")
    constrained_atoms = POS00.constraints[0].get_indices()
    relaxing_atoms_set=set(range(len(POS00)))- set(constrained_atoms)
    print("Relaxing atoms:", relaxing_atoms_set)
    POS00_constrained = POS00[constrained_atoms]
    #print(POS00_constrained)
    
    if initial_path:
        for sys in neb_folders:
            POS=ase.io.read('{}/POSCAR'.format(sys))
            for i in relaxing_atoms_set:
                POS_rlx = POS[i]
                POS00_constrained += POS_rlx
        ase.io.write("INIT_NEB_PATH.vasp", POS00_constrained, format='vasp')

    if final_path:
        POS=ase.io.read('{}/POSCAR'.format(neb_folders[0]))
        for i in relaxing_atoms_set:
            POS_rlx = POS[i]
            POS00_constrained += POS_rlx

        for sys in neb_folders[1:-1]:
            POS=ase.io.read('{}/CONTCAR'.format(sys))
            for i in relaxing_atoms_set:
                POS_rlx = POS[i]
                POS00_constrained += POS_rlx

        POS=ase.io.read('{}/POSCAR'.format(neb_folders[-1]))
        for i in relaxing_atoms_set:
            POS_rlx = POS[i]
            POS00_constrained += POS_rlx

        ase.io.write("OPT_NEB_PATH.vasp", POS00_constrained, format='vasp')


def init_neb_path():
    neb_path(initial_path=True, final_path=False)

neb_path()
