import os
import shutil
import subprocess
from pathlib import Path
from pymatgen.io.vasp import Outcar, Incar

import sys
sys.path.append("/mnt/research/barone/Useful_Codes/VaspWorks/PYTHONS")
from loop_pythons.lINCAR_mag import replace_magmom_from_OUTCAR



def modify_job_sh(
    job_file,
    new_job_file,
    job_name_prefix="",
    time="5-00:00:00",
    vasp_executable=None,
):
    job_file = Path(os.path.join(job_file.strip(), 'job.sh'))
    new_job_file = Path(os.path.join(new_job_file.strip(), 'job.sh'))

    lines = job_file.read_text().splitlines()

    new_lines = []

    for line in lines:
        if line.startswith("#SBATCH --job-name="):
            job_name = line.split("=", 1)[1].strip()
            line = f"#SBATCH --job-name={job_name_prefix}{job_name}"

        elif line.startswith("#SBATCH --job-name"):
            job_name = line.split("job-name", 1)[1].strip()
            line = f"#SBATCH --job-name {job_name_prefix}{job_name}"

        elif line.startswith("#SBATCH --time="):
            line = f"#SBATCH --time={time}"

        # Replace VASP executable
        if vasp_executable is not None:
            line = line.replace("vasp_std", vasp_executable)

        new_lines.append(line)

        if line.startswith("#SBATCH --ntasks"):
            new_lines.append("#SBATCH --nodes=1")

    new_job_file.write_text("\n".join(new_lines) + "\n")

    # Copy job.sh permissions (including executable bit)
    shutil.copymode(job_file, new_job_file)



def setup_aimd(drct, raimd_path="AIMD"):
    # cleaning drct path
    drct = drct.strip()

    Path(os.path.join(drct, raimd_path)).mkdir(parents=True, exist_ok=True)
    vaspworks_location = shutil.which("vasp_inp.sh")
    if vaspworks_location is None:
        raise FileNotFoundError("vasp_inp.sh not found in PATH")

    vaspworks_dir = Path(vaspworks_location).parent


    print("Copying KPOINTS_md from DATA:")
    shutil.copy(os.path.join(vaspworks_dir, "DATA", "KPOINTS_md"), os.path.join(drct, raimd_path, "KPOINTS"))


    #print("Copying CHGCAR file for faster convergence if available.")
    #shutil.copy(os.path.join(drct, "CHGCAR"), os.path.join(drct, rzpe_path, "CHGCAR"))

    shutil.copy(os.path.join(drct, "CONTCAR"), os.path.join(drct, raimd_path, "POSCAR"))
    shutil.copy(os.path.join(drct, "POTCAR"), os.path.join(drct, raimd_path, "POTCAR"))
    #shutil.copy(os.path.join(drct, "KPOINTS"), os.path.join(drct, raimd_path, "KPOINTS"))

    incar = Incar.from_file(os.path.join(drct, "INCAR"))

    # Not required tags
    incar.pop("EDIFFG", None)

    incar["SMASS"] = 0
    incar["TEBEG"] = 800 
    incar["TEEEG"] = 800 
    incar["NBLOCK"] = 1 
    incar["KBLOCK"] = 1 

    ## Medium-level output
    #incar["NWRITE"] = 2 
    incar["LCHARG"] = ".FALSE."
    #
    ## for better accuracy
    #incar["LREAL"] = ".FALSE."
    # for compatibility and efficient
    incar["NCORE"] = 8

    ## Frequency calculation required.
    # number of ionic steps. Make it odd.
    incar["NSW"]    =  5000           
    #gaussian smearing method
    incar["ISMEAR"] =  0           
    #please check the width of the smearing
    incar["SIGMA"]  =  0.05         
    #frequence calculation algorithm
    incar["IBRION"] =  0           
    # displacement step
    incar["POTIM"]  =  1         
    incar.write_file(os.path.join(drct, raimd_path, "INCAR"))
    replace_magmom_from_OUTCAR(drct, dst="AIMD", incar_out="INCAR")



#drct=os.getcwd()
#setup_aimd(drct)
#modify_job_sh(drct, f"{drct}/AIMD", vasp_executable="vasp_gam")

#with open("aimd_path.txt") as f:
#    lines=f.readlines()
#
#drct=os.getcwd()
#for line in lines:
#    line=line.strip()
#    if line.startswith("#"):
#        pass
#    else:
#        print(line)
#        setup_aimd(os.path.join(drct, line))
#        modify_job_sh(os.path.join(drct, line), os.path.join(drct, line, "AIMD"), job_name_prefix="m", vasp_executable="vasp_gam")
