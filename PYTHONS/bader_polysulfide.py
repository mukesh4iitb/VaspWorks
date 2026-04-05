import numpy as np

import ase.io 
import os
#from ase.data import atomic_numbers
from ase.units import Bohr


def attach_charges(atoms, fileobj='ACF.dat', displacement=1e-4):
    """Attach the charges from the fileobj to the Atoms."""
    if isinstance(fileobj, str):
        with open(fileobj) as fd:
            lines = fd.readlines()
    else:
        lines = fileobj

    sep = '---------------'
    i = 0  # Counter for the lines
    k = 0  # Counter of sep
    assume6columns = False
    for line in lines:
        if line[0] == '\n':  # check if there is an empty line in the
            i -= 1           # head of ACF.dat file
        if i == 0:
            headings = line
            if 'BADER' in headings.split():
                j = headings.split().index('BADER')
            elif 'CHARGE' in headings.split():
                j = headings.split().index('CHARGE')
            else:
                print('Can\'t find keyword "BADER" or "CHARGE".'
                      ' Assuming the ACF.dat file has 6 columns.')
                j = 4
                assume6columns = True
        if sep in line:  # Stop at last separator line
            if k == 1:
                break
            k += 1
        if i <= 1:
            pass
        else:
            words = line.split()
            if assume6columns is True:
                if len(words) != 6:
                    raise OSError('Number of columns in ACF file incorrect!\n'
                                  'Check that Bader program version >= 0.25')

            atom = atoms[int(words[0]) - 1]
            atom.charge = float(words[j])-ZVALs_dict[atom.symbol]
            if displacement is not None:  # check if the atom positions match
                xyz = np.array([float(w) for w in words[1:4]])
                # ACF.dat units could be Bohr or Angstrom
                norm1 = np.linalg.norm(atom.position - xyz)
                norm2 = np.linalg.norm(atom.position - xyz * Bohr)
                assert norm1 < displacement or norm2 < displacement
        i += 1

#def bader_charge_transfer(atoms, ZVALs_dict):
#    for atom in atoms:
#        atom.transfer_bader_charge = atom.charge-ZVALs_dict[atom.symbol]
#    return atoms


if __name__ == "__main__":
    paths = [
        "polyabosrbtion/Co/K2S/scf/",
        "polyabosrbtion/Co/K2S2/1_most/scf/"]
    
    drct=os.getcwd()
    for path in paths:
        full_path=os.path.join(drct, path)
        os.chdir(full_path)
    
        with open("POSCAR") as pos:
            lines = pos.readlines()
            symbols_line = lines[5]
            symbols = symbols_line.split()
        
        
        ZVALs = []
        with open("POTCAR") as pot:
            lines = pot.readlines()
            for line in lines:
                if "ZVAL" in line:
                    ZVALs.append(float(line.split()[5]))
        
        ZVALs_dict={}
        
        for sy, zv in zip(symbols, ZVALs):
            ZVALs_dict[sy]=zv
        
        #print(ZVALs_dict)
        
        
        atoms=ase.io.read("POSCAR")
        #print(atoms.get_chemical_symbols)
        attach_charges(atoms, displacement=None)
        
        polysulfide_charge=0
        for atom in atoms:
            if atom.symbol=="K" or atom.symbol=="S":
                polysulfide_charge += atom.charge
        
        print("polysulfide loss/gain charges:", polysulfide_charge)
        with open("polysufide_charge.txt", "w+") as f:
            f.write("{}: {}".format("polysulfide loss(-)/gain(+) charge", polysulfide_charge))
