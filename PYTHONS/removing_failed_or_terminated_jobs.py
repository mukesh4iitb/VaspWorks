import os
import shutil


drct=os.getcwd()
with open("f.txt") as f:
    lines=f.readlines()

for line in lines:
    print(line)
    os.chdir(os.path.join(drct, line.strip()))
    for root, subdirs, files in os.walk("."):
        for subs in subdirs:
            if subs.startswith(("FAIL", "TERM")):
                parts=subs.split("_")
                oe="{}_{}.o{}".format(parts[1], parts[2], parts[-2])
                #print(oe)
                for file in [oe, "OUTCAR", "OSZICAR", "CONTCAR", "vasp.out", "vasprun.xml", "XDATCAR"]:
                    if os.path.exists(file):
                        os.remove(file)
                shutil.rmtree(subs)
