#!/bin/bash

echo "Select an option:"
echo "01) Analyzing and continuing jobs"
echo "02) Finding outputs"
echo "03) Using vtst for smooth curve steps:"


vaspworks_location=$(which neb_post.sh)
vaspworks_dir=$(dirname $vaspworks_location)



source $vaspworks_dir/VASP_functions.sh  ## it is need to backup and cleaning vaspout files.

drct=$(pwd)

neb_folders=($(ls | grep -E '^[0-9]{2}$'))
POS_IN="${neb_folders[0]}"
POS_FN="${neb_folders[-1]}"



read -p "Enter your choice: " inp0
 
##### 01 section functions  ##########
neb_backingup_and_cleaning() {
for fold in "${neb_folders[@]}"
do
    if [[ "$fold" == "$POS_IN" || "$fold" == "$POS_FN" ]]; then
        continue  # Skip iteration for POS_IN and POS_FN
    fi

    cd "$drct/$fold"
    backup_poscar
    backup_outcar
    vasp_output_clean
done
}


##### 02 section functions  ##########

# Function to create XDATCAR_IN.vasp
create_XDATCAR_IN() {
	for fold in "${neb_folders[@]}"
	do
	    if [ "$fold" == "$POS_IN" ]; then
	        cat "$fold/POSCAR" > XDATCAR_IN.vasp
	    else
	        cat "$fold/POSCAR" >> XDATCAR_IN.vasp
	    fi
        sed -i -E 's/\b[FT]\s+[FT]\s+[FT]\b//g' XDATCAR_IN.vasp        
        sed -i '/Selective dynamics/d' XDATCAR_IN.vasp
        sed -i "/NaN/d" XDATCAR_IN.vasp
        sed -i '/^[[:space:]]*$/d' XDATCAR_IN.vasp
	done
}


# Function to create XDATCAR_IN.vasp
create_XDATCAR_FN() {
	for fold in "${neb_folders[@]}"
	do
	    if [ "$fold" == "$POS_IN" ]; then
	        len_pos=$(cat "$fold/POSCAR" | wc -l)
	        cat "$fold/POSCAR" > XDATCAR_FN.vasp
	    elif [ "$fold" == "$POS_FN" ]; then
	        cat "$fold/POSCAR" >> XDATCAR_FN.vasp
	    else
	        head -n $len_pos "$fold/CONTCAR" >> XDATCAR_FN.vasp
	    fi
        sed -i -E 's/\b[FT]\s+[FT]\s+[FT]\b//g' XDATCAR_FN.vasp        
        sed -i '/Selective dynamics/d' XDATCAR_FN.vasp
        sed -i "/NaN/d" XDATCAR_FN.vasp
        sed -i '/^[[:space:]]*$/d' XDATCAR_FN.vasp
        done
}


extract_energy() {
            ### Extracting energy from OSZICAR or OUTCAR files.
	for fold in "${neb_folders[@]}"
	do
            if [ -f "$POS_IN/OSZICAR" ]; then  # Extract energy from OSZICAR (if file exists)
                if [ "$fold" == "$POS_IN" ]; then
	            E0=$(grep "F=" "$fold/OSZICAR" | tail -n 1 | awk '{print $5}')
                    echo "## Energy from OSZICAR:" > neb_energy.txt
	            echo "$fold     $E0" >> neb_energy.txt
	        else
	            E0=$(grep "F=" "$fold/OSZICAR" | tail -n 1 | awk '{print $5}')
	            echo "$fold     $E0" >> neb_energy.txt
	        fi
            else  # Extract energy from OUTCAR
                if [ "$fold" == "$POS_IN" ]; then
	            E0=$(grep "free  energy   TOTEN" $fold/OUTCAR | tail -n 1 | awk '{print $5}')
                    echo "## Energy from OUTCAR:" > neb_energy.txt
	            echo "$fold     $E0" >> neb_energy.txt
	        else
	            E0=$(grep "free  energy   TOTEN" $fold/OUTCAR | tail -n 1 | awk '{print $5}')
	            echo "$fold     $E0" >> neb_energy.txt
	        fi
            fi
	done
}

case "$inp0" in
	"01" | "1" )
        echo "101: Continuing NEB jobs."
        read -p "Enter your choice: " inp1
        case "$inp1" in
                  101)
                  echo "backing up and cleaning NEB outputs"
                  neb_backingup_and_cleaning
                  ;;
        esac
        ;;
	"02" | "2")
        echo "201) XDATCAR_IN.vasp and INIT_NEB_PATH.vasp"
        echo "202) XDATCAR_FN.vasp, OPT_NEB_PATH.vasp, and neb_energy.txt"
        echo "203) XDATCAR_IN, XDATCAR_FN, INIT_NEB_PATH.vasp, OPT_NEB_PATH.vasp and neb_energy.txt"
        read -p "Enter your choice: " inp1
        case "$inp1" in
                 "201")
                 echo -e "\nCreating: XDATCAR_IN.vasp"
                 create_XDATCAR_IN
                 echo -e "\nCreating: INIT_NEB_POSCAR.vasp"
		 python3 $vaspworks_dir/PYTHONS/init_neb_path.py
                 ;;
                 
                 "202")
                 echo -e "\nCreating: XDATCAR_FN.vasp"
                 create_XDATCAR_FN
		
                 echo -e "\nCreating: OPT_NEB_POSCAR.vasp"
		 python3 $vaspworks_dir/PYTHONS/neb_path.py

                 echo -e "\nCreating: neb_energy.txt"
                 extract_energy	
                 ;;
                 
                 "203")
                 echo -e "\nCreating: XDATCAR_FN.vasp"
                 create_XDATCAR_IN

                 echo -e "\nCreating: INIT_NEB_POSCAR.vasp"
		 python3 $vaspworks_dir/PYTHONS/init_neb_path.py

                 echo -e "\nCreating: OPT_NEB_POSCAR.vasp"
		 python3 $vaspworks_dir/PYTHONS/neb_path.py

                 echo -e "\nCreating: XDATCAR_FN.vasp"
                 create_XDATCAR_FN

                 echo -e "\nCreating: neb_energy.txt"
                 extract_energy
                 ;;

                 *)
                 echo "Invalid option. Please choose a valid option"	
                 ;;
        esac
	;;
        "03" | "3")
                  echo "Steps for smooth NEB curves:"
		  echo "step0: module load gnuplot"
                  echo "Step1: nebbarrier.pl (generate neb.dat)"
                  echo "Step2: nebspline.pl  (read neb.dat and generate spline.dat, exts.dat and mep.eps)"
                  echo "ref: https://theory.cm.utexas.edu/vtsttools/scripts.html"
                  ;;
        *)
        echo "Invalid option. Please choose a valid option."
        ;;
esac
