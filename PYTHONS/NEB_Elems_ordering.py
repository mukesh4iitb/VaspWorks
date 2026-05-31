import os
import ase.io
import numpy as np
from ase.geometry import get_distances
from scipy.optimize import linear_sum_assignment


def functions():
    """Return a list of public functions in this module."""
    import inspect
    return sorted([
        name for name, obj in globals().items()
        if inspect.isfunction(obj) and not name.startswith("_")
    ])


def removing_cell_outside_atoms(POSCAR, POSCAR_clean):
    POS = ase.io.read(POSCAR, format='vasp')
    POS = POS[np.all((POS.get_scaled_positions(False) >= 0) & (POS.get_scaled_positions(False) < 1), axis=1)]
    ase.io.write(f"{POSCAR_clean}", POS, format='vasp')

def duplicate_remover(POSCAR_filename, POSCAR_clean_filename, tol=1e-5):
    """
    POSCAR_filename: Input POSCAR/CONTCAR file.
    POSCAR_clean_filename: Cleaned given input file.
    Note: this function just delete the duplicated atoms under the tol without changing order of atoms.
    """
    atoms = ase.io.read(POSCAR_filename, format='vasp')
    N = len(atoms)

    to_delete = set()
    tol = 1e-5

    for i in range(N):
        if i in to_delete:
            continue
        for j in range(i+1, N):
            if j in to_delete:
                continue
            d = atoms.get_distance(i, j, mic=True)  # periodic distance
            if abs(d) < tol:   # duplicate
                to_delete.add(j)

    # construct new atom list preserving order
    new_atoms = atoms[[i for i in range(N) if i not in to_delete]]
    ase.io.write("{}".format(POSCAR_clean_filename), new_atoms)

#duplicate_remover("POSCAR.vasp", "POSCAR_clean.vasp", tol=1e-5)


def duplicate_remover_with_wrap(POSCAR_filename, POSCAR_clean_filename, tol=1e-5):
    """
    Note: Sometime, using the removing_cell_outside_atoms does not work properly (of which reason, I don't know. Also, I have tried with different tol=1e-4 as below: still removing_cell_outside_atoms is not working:
    tol = 1e-4
    inside_atoms = np.all((scaled_positions >= -tol) & (scaled_positions <= 1 + tol), axis=1)
    POS1 = POS[inside_atoms]
    So the way out to this problem is wrapping all the atom inside the cell and deleting atom which are closer (1e-5) to each other. But this method is time consuming.
    An example, removing_cell_outside_atoms does not works is giving into removing_cell_and_deleting_not_working_so_way_out_method_is_removing_with_wrap.py

    POSCAR_filename: Input POSCAR/CONTCAR file.
    POSCAR_clean_filename: Cleaned given input file.
    Note: this function just delete the duplicated atoms under the tol without changing order of atoms.
    """
    atoms = ase.io.read(POSCAR_filename, format='vasp')
    atoms.wrap(pbc=[True, True, True])
    N = len(atoms)

    to_delete = set()
    tol = 1e-5

    for i in range(N):
        if i in to_delete:
            continue
        for j in range(i+1, N):
            if j in to_delete:
                continue
            d = atoms.get_distance(i, j, mic=True)  # periodic distance
            if abs(d) < tol:   # duplicate
                to_delete.add(j)

    # construct new atom list preserving order
    new_atoms = atoms[[i for i in range(N) if i not in to_delete]]
    ase.io.write("{}".format(POSCAR_clean_filename), new_atoms)




def NEB_ordering(POSCAR_IN, POSCAR_FN, tol=1e-3):
    """
    This function, I will write later as this  is not the most suitable ways to do this. 
    See map_atoms_by_distance and map_atoms_by_species_and_distance functions.
    """
    POS_IN = ase.io.read(POSCAR_IN)
    POS_FN = ase.io.read(POSCAR_FN)
    indices=[]
    for i in range(len(POS_IN)):
        index=int(np.argmin(np.linalg.norm(POS_IN.positions[i]-POS_FN.positions, axis=1)))
        dist=np.linalg.norm(POS_IN[i].position - POS_FN[index].position)
        if dist < tol:
            indices.append(index)
    
    remaining_indcies = set(range(len(POS_FN)))-set(indices)
    print("Atoms with indices seems to be moving:\n", remaining_indcies)
    POS_FN_ordered = POS_FN[indices] + POS_FN[list(remaining_indcies)]
    ase.io.write("{}_NEBOrdered.vasp".format(POSCAR_FN.split(".vasp")[0]), POS_FN_ordered, format='vasp')
#NEB_ordering("POSCAR_IN.vasp", "POSCAR_FN.vasp", tol=10e-3)

def NEB_ordering1(POSCAR_IN, POSCAR_FN, tol=1e-3):
    """
    This function, I will write later as this  is not the most suitable ways to do this. 
    See map_atoms_by_distance and map_atoms_by_species_and_distance functions.
    """
    POS_IN = ase.io.read(POSCAR_IN)
    POS_FN = ase.io.read(POSCAR_FN)
    indices=[]
    for i in range(len(POS_IN)):
        pos_i = POS_IN.positions[i]
        positions = POS_FN.positions
        Dvec, Dist = get_distances(pos_i, positions, cell=POS_FN.cell, pbc=POS_FN.pbc)
        index=int(np.argmin(Dist))
        #print(i,index, Dist)
        dvec, dist = get_distances(pos_i, positions[index], cell=POS_FN.cell, pbc=POS_FN.pbc)
        print(dist)

        if dist < tol:
            indices.append(index)
    
    remaining_indcies = set(range(len(POS_FN)))-set(indices)
    print("Atoms with indices seems to be moving:\n", remaining_indcies)
    POS_FN_ordered = POS_FN[indices] + POS_FN[list(remaining_indcies)]
    ase.io.write("{}_NEBOrdered.vasp".format(POSCAR_FN.split(".vasp")[0]), POS_FN_ordered, format='vasp')

#NEB_ordering1("POSCAR_IN.vasp", "POSCAR_FN.vasp", tol=10e-3)

def Unique_atoms(chemical_symbols):
    """
    This function take chemical symbols and provide the unique atoms without changing order.
    Note: using directly set function chemical_symbols list can change order.
    """
    unique_atoms = []
    for sym in chemical_symbols:
        if sym not in unique_atoms:
            unique_atoms.append(sym)
    print("Elemental order:\n", unique_atoms)
    return unique_atoms


def Elem_Ordering(POSCAR, POSCAR_ordered, preferred_order = None):
    """
    This function just order the elememts either two ways:
    i) If prefered_order is given, it use this to order elements.
    ii) else, it consider the first entry of each elements as order.

    POSCAR: input file.
    POSCAR_ordered: outfile.
    """
    POS = ase.io.read(POSCAR)
    chemical_symbols = POS.get_chemical_symbols()

    if preferred_order:
        order = preferred_order
    else:
        order = Unique_atoms(chemical_symbols)

    symbols = np.array(chemical_symbols)
    # Assign rank to each symbol
    rank = {s: i for i, s in enumerate(order)}
    default_rank = len(order)

    # Create sorted indices
    indices = sorted(
        range(len(POS)),
        key=lambda i: rank.get(symbols[i], default_rank)
    )
    ase.io.write("{}".format(POSCAR_ordered), POS[indices], format='vasp')

#Elem_Ordering("POS2.vasp", "POS2_ordered1.vasp")
#Elem_Ordering("POS2.vasp", "POS2_ordere2.vasp", ["C"   ,"N"   ,"H"   ,"Fe"  ,"Li"  ,"S"])


def NEB_Elem_ordering(POSCAR_IN, POSCAR_FN, tol):
    """
    I will write the docstring latter as this function is the most suitable ways to do.
    See NEB_Elem_ordering3, which using Linear sum assigment (LSA). LSA is implimented in scipy.
    """
    NEB_ordering(POSCAR_IN, POSCAR_FN, tol=tol)
    POS_IN = ase.io.read(POSCAR_IN)
    chemical_symbols = POS_IN.get_chemical_symbols()
    order = Unique_atoms(chemical_symbols)
    Elem_Ordering("{}_NEBOrdered.vasp".format(POSCAR_FN.split(".vasp")[0]), preferred_order=order)

    # deleting and renaming file for convenince.
    neb_ordered_file = "{}_NEBOrdered.vasp".format(POSCAR_FN.split(".vasp")[0])
    neb_elem_ordered_file="{}_NEBOrdered_ElemOrdered.vasp".format(POSCAR_FN.split(".vasp")[0])
    if os.path.exists(neb_elem_ordered_file):
        FN_ordered = "{}_ordered.vasp".format(POSCAR_FN.split(".vasp")[0]) 
        os.rename(neb_elem_ordered_file, FN_ordered)
    if os.path.exists(neb_ordered_file):
        os.remove(neb_ordered_file)

#NEB_Elem_ordering("POSCAR_IN.vasp", "POSCAR_FN.vasp")

def NEB_Elem_ordering1(POSCAR_IN, POSCAR_FN, tol):
    """
    I will write the docstring latter as this function is the most suitable ways to do.
    See NEB_Elem_ordering3, which using Linear sum assigment (LSA). LSA is implimented in scipy.
    """
    NEB_ordering1(POSCAR_IN, POSCAR_FN, tol=tol)
    POS_IN = ase.io.read(POSCAR_IN)
    chemical_symbols = POS_IN.get_chemical_symbols()
    order = Unique_atoms(chemical_symbols)
    Elem_Ordering("{}_NEBOrdered.vasp".format(POSCAR_FN.split(".vasp")[0]), preferred_order=order)

    # deleting and renaming file for convenince.
    neb_ordered_file = "{}_NEBOrdered.vasp".format(POSCAR_FN.split(".vasp")[0])
    neb_elem_ordered_file="{}_NEBOrdered_ElemOrdered.vasp".format(POSCAR_FN.split(".vasp")[0])
    if os.path.exists(neb_elem_ordered_file):
        FN_ordered = "{}_ordered.vasp".format(POSCAR_FN.split(".vasp")[0]) 
        os.rename(neb_elem_ordered_file, FN_ordered)
    if os.path.exists(neb_ordered_file):
        os.remove(neb_ordered_file)


#NEB_Elem_ordering("POSCAR_IN.vasp", "POSCAR_FN.vasp")


def clean_duplicate_and_elem_ordering(POSCAR, POSCAR_clean, preferred_order=None, tol=1e-5):
    """
    This is a convenience function for doing two task togeter:
    1) Cleaning the duplicate atoms. 
       See docs of duplicate_remover(). 
    2) Ordering elements using the specific given order or first entries. 
       See the docs of Elem_Ordering().
    """
    tmp = "{}_tmp.vasp".format(POSCAR_clean)
    duplicate_remover(POSCAR, tmp, tol=tol)
    Elem_Ordering(tmp, POSCAR_clean, preferred_order = None)

    if os.path.exists(tmp):
        os.remove(tmp)

#clean_duplicate_and_elem_ordering("POSCAR.vasp")



def map_atoms_by_distance(pos1, pos2):
    # distance matrix with PBC
    _, D = get_distances(
        pos1.positions,
        pos2.positions,
        cell=pos1.cell,
        pbc=pos1.pbc
    )

    row_ind, col_ind = linear_sum_assignment(D)

    # reorder pos2 to match pos1
    return pos2[col_ind]


def map_atoms_by_species_and_distance(ref_POSCAR, target_POSCAR, target_ordered_POSCAR):
    """
    ref_POSCAR : This is a POSCAR file, with w.r.t to what we want to orders targer POSCAR. 
    target_POSCAR: This is targer POSCAR, which will be ordered.
    target_ordered_POSCAR: This is output file after doing ordering using species and distance.
    """
    from collections import defaultdict

    ref = ase.io.read(ref_POSCAR)
    target = ase.io.read(target_POSCAR)

    new_indices = []

    for elem in set(ref.get_chemical_symbols()):
        ref_idx = [i for i,s in enumerate(ref.symbols) if s == elem]
        tgt_idx = [i for i,s in enumerate(target.symbols) if s == elem]

        _, D = get_distances(
            ref.positions[ref_idx],
            target.positions[tgt_idx],
            cell=ref.cell,
            pbc=ref.pbc
        )
        print(D)

        r, c = linear_sum_assignment(D)
        new_indices.extend((ref_idx[i], tgt_idx[j]) for i, j in zip(r, c))

    new_indices.sort()
    ordered_target=target[[j for _, j in new_indices]]
    ase.io.write(f"{target_ordered_POSCAR}", ordered_target, format='vasp')

#map_atoms_by_species_and_distance("POSCAR_IN.vasp", "POSCAR_FN.vasp", "POSCAR_ordered_FN.vasp")

def NEB_Elem_ordering3(POSCAR_IN, POSCAR_FN, POSCAR_IN_clean, POSCAR_FN_clean, preferred_order=None, tol=1e-5):
    """
    This is a convenience function which perform three task:
    1) It clean the duplicat atoms of both POSCAR_IN and POSCAR_FN
    2) It ordred both cleaned (removed duplicates) POSCAR_IN and POSCAR_FN by given preferred_order or first entries of elements.
    3) It make the order of POSCAR_FN with respect to POSCAR_IN.
    """

    clean_duplicate_and_elem_ordering(POSCAR_IN, POSCAR_IN_clean, preferred_order=None, tol=tol)
    tmp = "{}_tmp.vasp".format(POSCAR_FN_clean)
    clean_duplicate_and_elem_ordering(POSCAR_FN, tmp, preferred_order=None, tol=tol)

    map_atoms_by_species_and_distance(POSCAR_IN_clean, tmp, POSCAR_FN_clean)

    if os.path.exists(tmp):
        os.remove(tmp)

NEB_Elem_ordering3("POSCAR_IN.vasp", "POSCAR_FN.vasp", "POSCAR_IN_clean.vasp", "POSCAR_FN_clean.vasp")
