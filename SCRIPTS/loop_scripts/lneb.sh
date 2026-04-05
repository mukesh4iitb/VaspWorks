    if [[ "$drct" =~ /NEB$ ]]; then
        # Check if required files (KPOINTS, POTCAR, CONTCAR, INCAR) exist
        if [[ ! -f "$drct/POSCAR_IN.vasp" || ! -f "$drct/POSCAR_FN.vasp" || ! -f "$drct/POTCAR" || ! -f "$drct/KPOINTS"|| ! -f "$drct/INCAR" ]]; then
            echo 
            echo -e "\e[1;31m Error: \e[0m" "One or more required files (KPOINTS, POTCAR, CONTCAR, INCAR) are missing in $drct"
            echo "Copy these files from relaxed structure before proceeding with NEB!"
            echo 
            exit 1
        fi

        read -p "Want to apply selective dynamics to NEB? (yes/y): " want_sel_neb
        if [[ "$want_sel_neb" == "y" || "$want_sel_neb" == "yes" ]]; then
        python3 /mnt/home/k0122399/codes/myscripts/loop_scripts/lselective_dynamics_neb.py
        fi

        read -p "Enter number of IMAGES:" nimag
        nebmake.pl POSCAR_IN_Selective.vasp POSCAR_FN_Selective.vasp $nimag
        replace_add_INCAR_tag_with_external_value INCAR IMAGES $nimag
    else
        echo "You are not in an NEB directory. Create NEB before running it."
    fi
