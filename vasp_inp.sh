#!/bin/bash

vaspworks_location=$(which vasp_inp.sh)
vaspworks_dir=$(dirname $vaspworks_location)

source $vaspworks_dir/UTILS/vasp_inp_functions.sh


echo "sourcing" $vaspworks_dir/UTILS

echo "Select an option:"
echo "General (opt/dos/band)"
printf "%-25s%-25s\n" "101) rlx" "101l) lrlx.sh"
printf "%-25s%-25s\n" "102) dos" "102l) ldos.sh"
printf "%-25s%-25s\n" "103) bands" "103l) lbands.sh"
printf "%-25s%-25s\n" "104) hse-dos" "104l) lhse-dos.sh"
printf "%-25s%-25s\n" "105) hse-bands" "105l) lhse-bands.sh"

echo 
echo "ZPE/NEB calculations; IN=input, l=loop, p=post"
printf "%-25s%-35s\n" "201) Sel Dyn POSCAR" "201l) lselective_dynamics.py"
printf "%-25s%-35s%-25s\n" "202) ZPE-IN" "202l) lzpe.sh" "202p) pzpe.sh"
printf "%-25s%-35s%-25s\n" "203) NEB-IN" "203l) lneb.sh" "203p) neb_post.sh"

echo 
echo "Stability (AIMD/Phonon/Mechanical)"
printf "%-30s%s\n" "301) AIMD" "301l) laimd.sh"
printf "%-30s%s\n" "302) Phonon" "302l) lphonon.sh"
printf "%-30s%s\n" "303) Mech stability (Cij)" "303l) lmech_stability.sh"

echo 
echo "COHP/COOP/COBI analysis:"
printf "%-30s%s\n" "401) generate max_basis" "401l) copy lobster*.py files"
printf "%-30s%s\n" "402) Improve ICOXXLIST_lobster files for (lobsterpy)"

echo 

read -p "Enter your choice: " inp


case "$inp" in
    101 | "rlx" )
        echo "relaxation input (INCAR):"
        cp  $vaspworks_dir/DATA/INCAR_rlx  INCAR 
        ;;
    101l )
        echo "copying lrlx.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lrlx.sh .
        ;;
    102 | "dos")
        echo "dos input (INCAR):"
        cp  $vaspworks_dir/DATA/INCAR_dos_bader  INCAR 
        ;;
    102l )
        echo "copying ldos.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/ldos.sh .
        ;;
    103 | "bands")
        echo "bands input (INCAR):"
        cp  $vaspworks_dir/DATA/INCAR_band INCAR 
        echo "Running band structure calculations..."
        # Add your bands command here
        ;;
    103l )
        echo "copying lbands.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lbands.sh .
        ;;
    104 | "hse-dos")
        echo "dos input (INCAR):"
        #cp  /mnt/home/k0122399/vasp_check/inp/INCAR_rlx  INCAR
        echo "Running HSE-DOS calculations..."
        # Add your HSE-DOS command here
        ;;
    104l )
        echo "copying lhse_dos.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lhse_dos.sh .
        ;;
    105 | "hse-band")
        echo "dos input (INCAR):"
        cp  $vaspworks_dir/DATA/INCAR_hse_band INCAR
        echo "Running HSE-band calculations..."
        # Add your HSE-band command here
        ;;
    105l )
        echo "copying lhse_bands.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lhse_bands.sh .
        ;;

    201 )
        echo "Still tuning to select, which atoms to relax or which are not relax. So"
	echo "Copy lselective_dynamics.py using the 201l"
        ;;
    201l )
        echo "copying lgenerating_selective_dynamics_poscar.py:"
        cp $vaspworks_dir/PYTHONS/loop_pythons/lselective_dynamics.py .
        ;;

    202 )
       echo "copying "
       mkdir ZPE
       cp $vaspworks_dir/DATA/INCAR_ZPE_MJ ZPE/INCAR
       replace_add_INCAR_tag INCAR ZPE/INCAR MAGMOM ENCUT EDIFF EDIFFG IVDW
       cp CONTCAR ZPE/POSCAR
       cp POTCAR ZPE/POTCAR
       cp KPOINTS ZPE/KPOINTS
       cd ZPE
    read -p "Want to apply selective dynamics to ZPE? (yes/y): " want_sel_zpe
    if [[ "$want_sel_zpe" == "y" || "$want_sel_zpe" == "yes" ]]; then
       python3 $vaspworks_dir/SCRIPTS/loop_pythons/lselective_dynamics.py 
       fi
       cp POSCAR_Selective.vasp POSCAR
        ;;

    202l )
        echo "copying lzpe.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lzpe.sh .
        ;;

    203 )

    if [[ "$drct" =~ /NEB$ ]]; then
        # Check if required files (KPOINTS, POTCAR, CONTCAR, INCAR) exist
        if [[ ! -f "$drct/POSCAR_IN.vasp" || ! -f "$drct/POSCAR_FN.vasp" || ! -f "$drct/POTCAR" || ! -f "$drct/KPOINTS"|| ! -f "$drct/INCAR_rlx" ]]; then
            echo 
            echo -e "\e[1;31m Error: \e[0m" "One or more required files (KPOINTS, POTCAR, CONTCAR, INCAR_rlx) are missing in $drct"
            echo "Copy these files from relaxed structure before proceeding with NEB!"
            echo 
            exit 1
        fi
      
        read -p "Want to apply selective dynamics to NEB? (yes/y): " want_sel_neb
        if [[ "$want_sel_neb" == "y" || "$want_sel_neb" == "yes" ]]; then
        python3 $vaspworks_dir/SCRIPTS/loop_pythons/lselective_dynamics.py 
        fi
        cp $vaspworks_dir/DATA/INCAR_NEB_Henkelman $drct/INCAR
        read -p "Enter number of IMAGES:" nimag
        nebmake.pl POSCAR_IN_Selective.vasp POSCAR_FN_Selective.vasp $nimag
        replace_add_INCAR_tag_with_external_value $drct/INCAR IMAGES $nimag
        replace_add_INCAR_tag $drct/INCAR_rlx $drct/INCAR MAGMOM ENCUT EDIFF EDIFFG IVDW
        replace_add_INCAR_tag_with_external_value INCAR ISPIN 2  LORBMOM  .TRUE.  LORBIT 10
    else
        echo "You are not in an NEB directory. Create NEB before running it."
    fi

        ;;
    203l )
        echo "copying lneb.sh"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lneb.sh .
        ;;
    203p )
        echo "calling neb_post.sh script:"
        bash $vaspworks_dir/SCRIPTS/neb_post.sh 
        ;;

    301 )
       echo "creating md inp:"
       creating_md_inp
        ;;
    301l )
        echo "copying lmd.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lmd.sh .
        ;;
    302 )
       echo "creating phonon inp:"
       creating_phonon_inp
        ;;
    302l )
        echo "copying lphonon.sh:"
        cp $vaspworks_dir/SCRIPTS/loop_scripts/lphonon.sh .
        ;;
    303 | 303l )
        echo "Mechanical (Elastic) properties working on it."
        ;;
    401 )
	echo "generateing max_basis folder to run vasp:"
	python3 $vaspworks_dir/PYTHONS/lobsterInpImprove_and_generate_basis_max.py
	;;
    401l )
        echo "copying lobster*.py files for:"
	echo "1- generating max_basis and" 
	echo "2 -improving ICOXXLIST_lobster files (to work with lobsterpy)."
	cp $vaspworks_dir/PYTHONS/lobsterInpImprove_and_generate_basis_max.py .
	cp $vaspworks_dir/PYTHONS/lobsterpyInpImprove.py .
	;;
    403 )
        echo "Improving ICOXXLIST_lobster files (to work with lobsterpy)"
	python3 $vaspworks_dir/PYTHONS/lobsterpyInpImprove.py
	;;
    *)
        echo "Invalid option. Please choose a valid option."
        ;;
esac


# Call the functions
creating_potcar_system
creating_kpoints_system
copying_jobs_script
