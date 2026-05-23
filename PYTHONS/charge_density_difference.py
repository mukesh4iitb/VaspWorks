import os
import sys
from pathlib import Path
from pymatgen.io.vasp.outputs import Chgcar, VolumetricData
from pymatgen.io.common import VolumetricData as CommonVolumetricData

def get_submit_scratch_dirs(path="."):
    oe_files = list(Path(path).glob("*.o[0-9]*"))

    if len(oe_files) == 0:
        raise FileNotFoundError(f"No .o<number> file found in {path}")

    elif len(oe_files) > 1:
        raise RuntimeError(
            f"Multiple .o<number> files found in {path}:\n"
            + "\n".join(str(f) for f in oe_files))

    oe_file = oe_files[0]
    scratch_dir = None
    submit_dir = None

    with open(oe_file, "r") as f:
        for line in f:
            if line.startswith("SCRATCH DIR:"):
                scratch_dir = line.replace(
                    "SCRATCH DIR:", ""
                ).strip()

            elif line.startswith("SUBMIT DIR:"):
                submit_dir = line.replace(
                    "SUBMIT DIR:", ""
                ).strip()

    return {
        "oe_file": str(oe_file),
        "scratch_dir": scratch_dir,
        "submit_dir": submit_dir,
    }

#print(get_submit_scratch_dirs())


def cdd(chgcar_AB_file, chgcar_A_file, chgcar_B_file):
    print(f"Reading:{chgcar_AB_file}")
    chgcar_AB = Chgcar.from_file(chgcar_AB_file)
    print(f"Reading:{chgcar_A_file}")
    chgcar_A = Chgcar.from_file(chgcar_A_file)
    print(f"Reading:{chgcar_B_file}")
    chgcar_B = Chgcar.from_file(chgcar_B_file)
    poscar = chgcar_AB.poscar  # strucutre of total system 
    data_diff = chgcar_AB.data['total'] - chgcar_A.data['total'] - chgcar_B.data['total']  # difference of grid data
    volumetric_diff = VolumetricData(structure=poscar.structure, data={'total': data_diff})
    print(f"Writing: CHGDIFF.vasp")
    volumetric_diff.write_file('CHGDIFF.vasp')


if __name__ == "__main__":

    name_AB=sys.argv[1]
    name_A=sys.argv[2]
    name_B=sys.argv[3]
    
    chgcar_AB=os.path.join(get_submit_scratch_dirs(f"{name_AB}")["scratch_dir"], "CHGCAR")
    chgcar_A=os.path.join(get_submit_scratch_dirs(f"{name_A}")["scratch_dir"], "CHGCAR")
    chgcar_B=os.path.join(get_submit_scratch_dirs(f"{name_B}")["scratch_dir"], "CHGCAR")
    
    #print(chgcar_AB)
    #print(chgcar_A)
    #print(chgcar_B)
    cdd(chgcar_AB, chgcar_A, chgcar_B)
