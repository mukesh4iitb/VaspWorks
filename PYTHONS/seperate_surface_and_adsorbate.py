import sys
import ase.io

def seperate_surf_and_absorbate(CONTCAR, MPSs_symbols):
    CONT=ase.io.read(CONTCAR)
    surf_idx=[]
    MPSs_idx=[]
    for i, atom in enumerate(CONT):
        if atom.symbol in MPSs_symbols:
            MPSs_idx.append(i)
        else:
            surf_idx.append(i)
    
    #print(MPSs_idx)
    #print(surf_idx)
    MPSs=CONT[MPSs_idx]
    surf=CONT[surf_idx]
    
    ase.io.write("{}_{}.vasp".format(CONTCAR, MPSs.get_chemical_formula()), MPSs)
    ase.io.write("{}_surf.vasp".format(CONTCAR), surf)


# to get help the following can be tested and added into the script.
# def main():
#     parser = argparse.ArgumentParser(
#         description="Separate surface and adsorbate atoms from a VASP CONTCAR/POSCAR file.",
#         epilog="""
# Examples:
#   python3 mycode.py CONTCAR K S
#   python3 mycode.py POSCAR Li S
#   python3 mycode.py structure.vasp Na S O
# """,
#         formatter_class=argparse.RawTextHelpFormatter
#     )

#     parser.add_argument(
#         "structure_file",
#         help="Input POSCAR/CONTCAR structure file"
#     )

#     parser.add_argument(
#         "elements",
#         nargs="+",
#         help="Adsorbate element symbols (space separated)"
#     )

#     args = parser.parse_args()

#     seperate_surf_and_absorbate(
#         args.structure_file,
#         args.elements
#     )





if __name__ == "__main__":
    # Example:
    # python script.py CONTCAR K S

    CONTCAR = sys.argv[1]
    MPSs_symbols = sys.argv[2:]

    seperate_surf_and_absorbate(CONTCAR, MPSs_symbols)
