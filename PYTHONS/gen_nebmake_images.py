import ase.io
import numpy as np
from pathlib import Path


POSCAR_init, POSCAR_final, num_images = input("Enter POSCAR_IN, POSCAR_FN, Number of images:\n").strip().split()
num_images = int(num_images)

POS1 = ase.io.read(POSCAR_init)
POS2 = ase.io.read(POSCAR_final)

dist = POS2.positions-POS1.positions
dist=dist/(num_images+1)


tol = 1e-6
if not np.allclose(POS1.cell.array, POS2.cell.array, atol=tol):
    raise ValueError(
        "Initial and final structures have different lattice vectors. "
        "Standard NEB requires identical cells.")

print(f"Cell parameters are Okay (tolerance={tol:.1e} Å).")

print(f"Creating directories 00 .. {num_images+1:02d}")



for i in range(num_images+2):
    #print(i)
    Path(f"{i:02d}").mkdir(parents=True, exist_ok=True)
    if i==0:
        ase.io.write(f"{i:02d}/POSCAR", POS1, format='vasp', direct=True)
    elif i==(num_images+2):
        ase.io.write(f"{i:02d}/POSCAR", POS2, format='vasp', direct=True)
    else:
        POS1.positions += dist
        ase.io.write(f"{i:02d}/POSCAR", POS1, format='vasp', direct=True)
