#!/mnt/ufs18/rs-028/barone/python3.11.3/bin/python3

##### written by Dr. Mukesh Singh ###
import os
import glob

def improve_ICOXXLIST_lobster(filename):
    with open(filename, "rb+") as f:
        lines = f.readlines()
    
        # Filter out undesired line
        new_lines = []
        for line in lines:
            if b"spin 1" in line and b"spin 2" not in line:
                continue
            new_lines.append(line)

        # Ensure last line ends with a newline
        if new_lines and not new_lines[-1].endswith(b'\n'):
            new_lines[-1] += b'\n'

        # Go to beginning, truncate, and write cleaned content
        f.seek(0)
        f.truncate()
        f.writelines(new_lines)
        print("Improved {}".format(filename))

drct=os.getcwd()
for root, subdirs, files in os.walk(drct):
    for file in files:
        if file.endswith('.lobster'):
            if file=="ICOHPLIST.lobster":
                improve_ICOXXLIST_lobster("ICOHPLIST.lobster")
            if file=="ICOOPLIST.lobster":
                improve_ICOXXLIST_lobster("ICOOPLIST.lobster")
            if file=="ICOBILIST.lobster":
                improve_ICOXXLIST_lobster("ICOBILIST.lobster")

# I might need to use this function for the following as well.
#ICOHPLIST.LCFO.lobster , ICOBILIST.LCFO.lobster IMOFELIST.lobster
