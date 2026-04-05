#!/bin/bash

creating_potcar () {
    local pbe_potcar_path="$1"   # First argument: path to POTCAR files
    local pot_elems=($2)         # Convert second argument to an array
    local pot_type="$3"          # Third argument (not used currently, but kept for extensibility)

    for elem in "${pot_elems[@]}"; do  # Properly iterate over elements
        echo "$elem"
        if [[ -f "$pbe_potcar_path/$elem/POTCAR" ]]; then
            cat "$pbe_potcar_path/$elem/POTCAR" >> POTCAR
        else
            echo "POTCAR not found for $elem. Available options:" 
            ls -d "$pbe_potcar_path/$elem"_*/ 2>/dev/null | xargs -n1 basename

            read -p "Enter the correct POTCAR directory for $elem: " new_elem
            if [[ -f "$pbe_potcar_path/$new_elem/POTCAR" ]]; then
                cat "$pbe_potcar_path/$new_elem/POTCAR" >> POTCAR
            else
                echo "POTCAR still not found for $new_elem. Skipping..."
            fi
        fi
    done
}


creating_gw_potcar () {
    local pbe_potcar_path="$1"   # First argument: path to POTCAR files
    local pot_elems=($2)         # Convert second argument to an array
    local pot_type="$3"          # Third argument (not used currently, but kept for extensibility)

    for elem in "${pot_elems[@]}"; do  # Properly iterate over elements
        echo "$elem"
        if [[ -f "$pbe_potcar_path/${elem}_GW/POTCAR" ]]; then
            cat "$pbe_potcar_path/${elem}_GW/POTCAR" >> POTCAR
        else
            echo "GW POTCAR not found for $elem. Available options:" 
            ls -d "$pbe_potcar_path/$elem"_*_GW/ 2>/dev/null | xargs -n1 basename

            read -p "Enter the correct POTCAR directory for $elem: " new_elem
            if [[ -f "$pbe_potcar_path/$new_elem/POTCAR" ]]; then
                cat "$pbe_potcar_path/$new_elem/POTCAR" >> POTCAR
            else
                echo "POTCAR still not found for $new_elem. Skipping..."
            fi
        fi
    done
}


replace_add_INCAR_tag() {
    local incar1=$1
    local incar2=$2
    shift 2  # Remove first two arguments
    local tags=("$@")

    for tag in "${tags[@]}"; do
            #echo reading $tag
            value=$(awk -F '=' -v key="$tag" '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); if ($1 == key) print $2}' "$incar1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            #echo $tag : $value

            # Check if the value is empty
            if [ -z "$value" ]; then
                echo "Warning: $tag not found or is commented out in $incar1"
                continue
            fi

            if grep -q "[[:space:]]*$tag[[:space:]]*=" "$incar2"; then
                sed -i "/[[:space:]]*$tag[[:space:]]*=/c\\$tag = $value" "$incar2"
                echo "Replacing $tag in INCAR"
            else
                echo "$tag = $value" >> "$incar2"
                echo "Adding $tag in INCAR"
            fi
    done
}

replace_add_INCAR_tag_with_external_value() {
    local args=("$@")
    local len=${#args[@]}

    if (( len % 2 == 0 )); then
        echo "Error: All tags does not have their values."
        return 1
    fi

    for ((i=1; i<len; i+=2)); do
        tag=${args[i]}
        value=${args[i+1]}

        echo $tag : $value

        if grep -q "[[:space:]]*$tag[[:space:]]*=" "${args[0]}"; then
            sed -i "/[[:space:]]*$tag[[:space:]]*=/c\\$tag = $value" "${args[0]}"
            echo "Replacing $tag in INCAR"
        else
            echo "$tag = $value" >> "${args[0]}"
            echo "Adding $tag in INCAR"
        fi
    done
}
# Function to create POTCAR
creating_potcar_system() {
    read -p "New POTCAR? (yes/y to proceed): " want_pot
    want_pot=$(echo "$want_pot" | tr '[:upper:]' '[:lower:]')

    if [[ "$want_pot" == "yes" || "$want_pot" == "y" ]]; then
        rm -f POTCAR 
        pbe_potcar_path=/mnt/home/k0122399/vasp_potentials/potpaw_PBE.52
        pot_elems=$(sed -n '6p' POSCAR)
        creating_potcar  "$pbe_potcar_path" "$pot_elems" "$pot_type"

    elif [[ "$want_pot" == "gw" ]]; then
        rm -f POTCAR 
        pbe_potcar_path=/mnt/home/k0122399/vasp_potentials/potpaw_PBE.52
        pot_elems=$(sed -n '6p' POSCAR)
        creating_gw_potcar  "$pbe_potcar_path" "$pot_elems" "$pot_type"

    elif [[ "$want_pot" == "lda-pbe" ]]; then
        rm -f POTCAR 
        pbe_potcar_path=/mnt/home/k0122399/vasp_potentials/potpaw_LDA.52
        pot_elems=$(sed -n '6p' POSCAR)
        creating_potcar  "$pbe_potcar_path" "$pot_elems" "$pot_type"

    elif [[ "$want_pot" == "lda-gw" ]]; then
        rm -f POTCAR 
        pbe_potcar_path=/mnt/home/k0122399/vasp_potentials/potpaw_LDA.52
        pot_elems=$(sed -n '6p' POSCAR)
        creating_gw_potcar  "$pbe_potcar_path" "$pot_elems" "$pot_type"
    fi
}

# Function to create KPOINTS using vaspkit
creating_kpoints_system() {
    read -p "(vaspkit) KPOINTS? (yes/y): " want_kpt
    want_kpt=$(echo "$want_kpt" | tr '[:upper:]' '[:lower:]')

    if [[ "$want_kpt" == "yes" || "$want_kpt" == "y" ]]; then
        vaspkit
    fi
}

# Function to copy job.sh script
copying_jobs_script() {
    read -p "job.sh ? (yes/y): " want_jobscript
    want_jobscript=$(echo "$want_jobscript" | tr '[:upper:]' '[:lower:]')

    if [[ "$want_jobscript" == "yes" || "$want_jobscript" == "y" ]]; then
        cp /mnt/home/k0122399/vasp_check/job.sh . 
    fi
}


creating_md_inp() {
    # Checking whether the current directory ends with md
    if [[ "$drct" =~ /md$ ]]; then    
        # Check if required files (KPOINTS, POTCAR, CONTCAR, INCAR) exist
        if [[ ! -f "$drct/CONTCAR" || ! -f "$drct/KPOINTS" || ! -f "$drct/POTCAR" || ! -f "$drct/INCAR" ]]; then
            echo 
            echo -e "\e[1;31m Error: \e[0m" "One or more required files (KPOINTS, POTCAR, CONTCAR, INCAR) are missing in $drct"
            echo "Copy these files from relaxed structure before proceeding with AIMD!"
            echo 
            exit 1
        fi

        echo "Creating step1 and step2."
        mkdir -p step1 step2

        # Step 1: Copying AIMD inputs (POSCAR, POTCAR, KPOINTS, INCAR) to step1
        echo "Copying AIMD inputs (POSCAR, POTCAR, KPOINTS, INCAR) to step1"
        cp $drct/CONTCAR $drct/step1/POSCAR
        cp $drct/POTCAR  $drct/step1
        cp /mnt/home/k0122399/vasp_check/inp/INCAR_md_step1 $drct/step1/INCAR
        cp /mnt/home/k0122399/vasp_check/inp/KPOINTS_md      $drct/step1/KPOINTS
        replace_add_INCAR_tag INCAR $drct/step1/INCAR  ENCUT EDIFF IVDW

        # Step 2: Copying AIMD inputs (POSCAR, POTCAR, KPOINTS, INCAR) to step2
        echo "Copying AIMD inputs (POSCAR, POTCAR, KPOINTS, INCAR) to step2"
        cp $drct/CONTCAR $drct/step2/POSCAR
        cp $drct/POTCAR  $drct/step2
        cp /mnt/home/k0122399/vasp_check/inp/INCAR_md_step2 $drct/step2/INCAR
        cp /mnt/home/k0122399/vasp_check/inp/KPOINTS_md      $drct/step2/KPOINTS
        replace_add_INCAR_tag INCAR $drct/step1/INCAR  ENCUT EDIFF IVDW
    else
        echo "You are not in an md directory. Create md before running it."
    fi
}


creating_phonon_inp() {
    # Checking whether the current directory ends with phonon
    if [[ "$drct" =~ /phonon$ ]]; then    
        # Check if required files (CONTCAR, KPOINTS, POTCAR, INCAR) exist
        if [[ ! -f "$drct/CONTCAR" || ! -f "$drct/KPOINTS" || ! -f "$drct/POTCAR" || ! -f "$drct/INCAR" ]]; then
            echo 
            echo -e "\e[1;31m Error: \e[0m" "One or more required files (KPOINTS, POTCAR, CONTCAR, INCAR) are missing in $drct"
            echo "Copy these files from tightly relaxed structure before proceeding with phonon!"
            echo 
            exit 1
        fi
        
        echo "Creating dfpt_ph and finit_ph directories."
        mkdir -p dfpt_ph finit_ph
        
        # Ask for phonon dimensions and unit file
        echo -e "(phonopy) Enter 3 dimensions and unit filename separated by space:\n"
        read dim1 dim2 dim3 unit_file
        
        # Run phonopy to generate the necessary phonon calculations
        phonopy -d --dim $dim1 $dim2 $dim3 -c $unit_file
        
        # Step 1: Copying DFTP-phonon inputs (SPOSCAR, POTCAR, KPOINTS, INCAR) to dfpt_ph
        echo "Copying DFTP-phonon inputs (SPOSCAR, POTCAR, KPOINTS, INCAR) to dfpt_ph"
        cp $drct/SPOSCAR $drct/dfpt_ph/POSCAR
        cp $drct/POTCAR  $drct/dfpt_ph
        cp $drct/KPOINTS $drct/dfpt_ph
        cp /mnt/home/k0122399/vasp_check/inp/INCAR_ph_dfpt $drct/dfpt_ph/INCAR
        replace_add_INCAR_tag INCAR $drct/dfpt_ph/INCAR ENCUT EDIFF IVDW
        
        # Step 2: Copying Finite-phonon inputs (POSCAR-ns, POTCAR, KPOINTS, INCAR) to finit_ph
        echo "Copying Finite-phonon inputs (POSCAR-ns, POTCAR, KPOINTS, INCAR) to finit_ph"
        cp $drct/POSCAR-* $drct/finit_ph/
        cp $drct/POTCAR  $drct/finit_ph
        cp $drct/KPOINTS $drct/finit_ph
        cp /mnt/home/k0122399/vasp_check/inp/INCAR_ph_finit $drct/finit_ph/INCAR
        
        # Copying the finite-phonon script (fph.sh)
        echo "Copying fph.sh for managing finite-phonon files."
        cp /mnt/home/k0122399/vasp_check/inp/fph.sh $drct/finit_ph/
        
        # Add necessary INCAR tags for finit_ph
        replace_add_INCAR_tag INCAR $drct/finit_ph/INCAR ENCUT EDIFF EDIFFG IVDW
        
    else
        echo "You are not in the phonon directory. Create phonon before running it."
    fi
}



# Call the functions
#creating_potcar_system
#creating_kpoints_system
#copying_jobs_script
#replace_add_INCAR_tag  INCAR1 INCAR2 ENCUT 
#creating_md_inp
#creating_phonon_inp

