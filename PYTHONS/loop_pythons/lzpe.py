import os
import shutil
from pathlib import Path
from pymatgen.io.vasp import Outcar, Incar

import sys
sys.path.append("/mnt/research/barone/Useful_Codes/VaspWorks/PYTHONS")
from loop_pythons.lINCAR_mag import replace_magmom_from_OUTCAR




def modify_job_sh(
    job_file,
    new_job_file,
    job_name_prefix="",
    time="4-00:00:00",
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
        new_lines.append(line)
    
    new_job_file.write_text("\n".join(new_lines) + "\n")
    # Copy job.sh file permissions to new_job_file (including executable bit)
    shutil.copymode(job_file, new_job_file)



def setup_zpe(drct, rzpe_path="ZPE"):
    # cleaning drct path
    drct = drct.strip()

    Path(os.path.join(drct, rzpe_path)).mkdir(parents=True, exist_ok=True)
    vaspworks_location = shutil.which("vasp_inp.sh")
    if vaspworks_location is None:
        raise FileNotFoundError("vasp_inp.sh not found in PATH")

    vaspworks_dir = Path(vaspworks_location).parent


    #print("Copying INCAR_ZPE_MJ for comparison")
    #shutil.copy(os.path.join(vaspworks_dir, "DATA", "INCAR_ZPE_MJ"), os.path.join(drct, rzpe_path))


    print("Copying CHGCAR file for faster convergence if available.")
    shutil.copy(os.path.join(drct, "CHGCAR"), os.path.join(drct, rzpe_path, "CHGCAR"))

    shutil.copy(os.path.join(drct, "CONTCAR"), os.path.join(drct, rzpe_path, "POSCAR"))
    shutil.copy(os.path.join(drct, "POTCAR"), os.path.join(drct, rzpe_path, "POTCAR"))
    shutil.copy(os.path.join(drct, "KPOINTS"), os.path.join(drct, rzpe_path, "KPOINTS"))

    incar = Incar.from_file(os.path.join(drct, "INCAR"))

    # Not required tags
    incar.pop("EDIFFG", None)
    
    # to make to faster convergence
    incar["ICHARG"] = 1
    incar["ADDGRID"] = ".TRUE." 

    # Medium-level output
    incar["NWRITE"] = 2          
    
    # for better accuracy
    incar["LREAL"] = ".FALSE."
    ## Frequency calculation required.
    # number of ionic steps. Make it odd.
    incar["NSW"]    =  1           
    #gaussian smearing method
    incar["ISMEAR"] =  0           
    #please check the width of the smearing
    incar["SIGMA"]  =  0.05         
    #frequence calculation algorithm
    incar["IBRION"] =  5           
    # displacement step
    incar["POTIM"]  =  0.02         
    # displacement freedom
    incar["NFREE"]  =  2 
    incar.write_file(os.path.join(drct, rzpe_path, "INCAR"))
    replace_magmom_from_OUTCAR(drct, dst="ZPE", incar_out="INCAR")

    print()
    print("Need to constrained atoms for ZPE")
    print()


#setup_zpe()
#modify_job_script("job.sh", "ZPE/job.sh")

#with open("zpe_path.txt") as f:
#    lines=f.readlines()
#
#drct=os.getcwd()
#for line in lines:
#    line=line.strip()
#    print(line)
#    setup_zpe(os.path.join(drct, line))
#    modify_job_sh(os.path.join(drct, line), os.path.join(drct, line, "ZPE"), job_name_prefix="z")
