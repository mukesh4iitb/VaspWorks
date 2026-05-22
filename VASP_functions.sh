#!/usr/bin/bash

vasp_inp_check() {
echo -e "\e[1;32m POSCAR: \e[0m"
head POSCAR
echo -e "\e[1;32m POTCAR: \e[0m"
grep "PAW_PBE" POTCAR
echo -e "\e[1;32m INCAR: \e[0m"
grep "MAGMOM" INCAR
echo -e "\e[1;32m KPOINTS: \e[0m"
head KPOINTS
}
# just run into the directory vasp running directory.
# vasp_inp_check


vasp_rlx_clean() { 
rm -f CHG CHGCAR DOSCAR EIGENVAL IBZKPT LOCPOT  PCDAT POT PROCAR REPORT  WAVECAR
ls
}

vasp_output_clean() { 
rm -f CHG CHGCAR CONTCAR OUTCAR OSZICAR DOSCAR EIGENVAL IBZKPT LOCPOT  PCDAT POT PROCAR REPORT vasprun.xml WAVECAR XDATCAR
ls
}


## backing up POSCAR, OUTCAR and OSZICAR files:

backup_poscar() {
    #lowest negative was first one to be executed and so on.
    # Maximum backup index is 9 (if needed adjust it)
    local i
    local max_backup
    max_backup=9

    # backup only required if CONTCAR exists
    if [[ ! -s "CONTCAR" ]]; then
    return  # Exit if CONTCAR doesn't exist OR is empty
    fi

    # if POSCAR_init does not exit, create one.
    if [[ -e "POSCAR" && ! -e "POSCAR_init" ]]; then
        cp "POSCAR" "POSCAR_init"
    fi

    for ((i=max_backup; i>=0; i--)); do
        if [[ -e "POSCAR-$i" ]]; then
            mv "POSCAR-$i" "POSCAR-$((i+1))"
        fi
    done

    if [[ -e "POSCAR" ]]; then
        mv "POSCAR" "POSCAR-0"
    fi

    mv "CONTCAR" "POSCAR"
}

backup_outcar() {
    #lowest negative was first one to be generated and so on.
    max_backup=9  # Maximum backup index is 9 (if needed adjust it)

    # backup only required if OUTCAR exists
    if [[ ! -s "OUTCAR" ]]; then
        return  # Exit function if CONTCAR doesn't exist
    fi

    for ((i=max_backup; i>=0; i--)); do
        if [[ -e "OUTCAR-$i" ]]; then
            mv "OUTCAR-$i" "OUTCAR-$((i+1))"
        fi
    done

    mv "OUTCAR" "OUTCAR-0"
}

backup_oszicar() {
    #lowest negative was first one to be generated and so on.
    max_backup=9  # Maximum backup index is 9 (if needed adjust it)

    # backup only required if OSZICAR exists
    if [[ ! -s "OSZICAR" ]]; then
        return  # Exit function if CONTCAR doesn't exist
    fi

    for ((i=max_backup; i>=0; i--)); do
        if [[ -e "OSZICAR-$i" ]]; then
            mv "OSZICAR-$i" "OSZICAR-$((i+1))"
        fi
    done

    mv "OSZICAR" "OSZICAR-0"
}



backup_anyfile() {
    #lowest negative was first one to be executed and so on.
    max_backup=9  # Maximum backup index is 9 (if needed adjust it)
    inpfile="$1"
    init_flag="${2:-0}"
    if [[ ! -s $inpfile ]]; then
        return  # Exit function if CONTCAR doesn't exist
    fi

    # if ${inpfile}_init does not exit and second flag is 1 then create one.
    if [[ $init_flag == 1 && ! -e "${inpfile}_init" ]]; then
        cp "$inpfile" "${inpfile}_init"
    fi

    for ((i=max_backup; i>=0; i--)); do
        if [[ -e "$inpfile-$i" ]]; then
            mv "$inpfile-$i" "$inpfile-$((i+1))"
        fi
    done

    mv "$inpfile" "$inpfile-0"
}

#backup_poscar
#backup_outcar
#backup_oszicar
#backup_anyfile vasp.out

check_vasp_outputs_presence() {
    local dir="$1"  # text file containing list of directories
    local files=("OUTCAR" "OSZICAR" "XDATCAR" "vasp.out" "CONTCAR" "POSCAR")

    for f in "${files[@]}";
     do
        if [[ -f "$dir/$f" ]]; then
            echo "✅ Found: $dir/$f"
        else
            echo "❌ Missing: $dir/$f"
        fi
     done
    }


#check_vasp_outputs_presence $drct

check_vasp_outputs_presence_from_submit_and_conti_dirs() {
    local line="$1"                 # Path to process

    # Initialize
    local path_str=""
    local dir0="$line"
    local count=0
    local base_name
    base_name=$(basename "$dir0")

    # Collect all nested conti paths
    while [[ "$base_name" == "conti" ]]; do
        path_str="$dir0 $path_str"
        local dir1
        dir1=$(dirname "$dir0")
        base_name=$(basename "$dir1")
        dir0="$dir1"
        ((count++))
        #echo "$dir0"
    done

    local submit_dir="$dir0"
        echo "------------------------------------------------------------------"

        # Check VASP outputs in submit directory
        check_vasp_outputs_presence "$submit_dir"

        # Check in each conti directory
        for path0 in $path_str; do
            check_vasp_outputs_presence "$path0"
        done

    echo "Submit directory: $submit_dir"
    echo "Conti directories: $path_str"

}

# check_vasp_outputs_presence_with_submit_and_conti_dirs $line


backup_vasp_outputs_from_submit_and_conti_dirs() {
        local final_completed_conti_dir="$1"
        local conti_path_str=""
        submit_dir0=$final_completed_conti_dir
        submit_base=$(basename $submit_dir0)
        while [[ "$submit_base" == "conti" ]];
        do
                conti_path_str="$submit_dir0 $conti_path_str"
                submit_dir1=$(dirname $submit_dir0)
                submit_base=$(basename $submit_dir1)
                submit_dir0=$submit_dir1
        done
        submit_dir=$submit_dir0

        echo "conti path-dir:" $conti_path_str
        echo "submit-dir:" $submit_dir

        for conti_path in $conti_path_str
        do
                cd $submit_dir || exit
                backup_poscar
                backup_outcar
                backup_oszicar
                backup_anyfile XDATCAR
                backup_anyfile vasp.out
                cp $conti_path/CONTCAR $submit_dir
                cp $conti_path/OUTCAR $submit_dir
                cp $conti_path/OSZICAR $submit_dir
                cp $conti_path/XDATCAR $submit_dir
                cp $conti_path/vasp.out $submit_dir

                if [[ -f "$conti_path/DONE" ]]; then
                cp $conti_path/DONE $submit_dir
                fi
        done
        echo "Need to delete: " $conti_path_str
}

#completed_conti_2_initial_submit_dir $drct/Li2S4_0/TERMINATED_mCo_Li2S4_64771360_2025-11-26/conti


forward_backup() {
    drct=$(pwd)
    conti="$1"

    if [[ -d "$drct/$conti" ]]; then
        if [[ -z "$conti" ]]; then
        echo "Usage: forward_backup <folder_name>"
        return 1
        else
        # Find the next available POSCAR-N filename

        cp $drct/POSCAR-*      "$drct/$conti/" 2>/dev/null
        cp $drct/OUTCAR-*      "$drct/$conti/" 2>/dev/null
        cp $drct/OSZICAR-*     "$drct/$conti/" 2>/dev/null
        cp $drct/vasprun-*.xml "$drct/$conti/" 2>/dev/null


        i=0
        while [[ -e "$drct/POSCAR-$i" ]]; do
                #echo "copying $i to $((i+1))"
            ((i++))
        done


        #echo "After loop: $i" 
        echo "Copying to $drct/$conti"
            cp "$drct/POSCAR" "$drct/$conti/POSCAR-$i"
            cp "$drct/OUTCAR" "$drct/$conti/OUTCAR-$i"
            cp "$drct/OSZICAR" "$drct/$conti/OSZICAR-$i"
            cp "$drct/vasprun.xml" "$drct/$conti/vasprun-$i.xml"
        fi
    else
        echo "Given folder does not exist"
    fi
}

#forward_backup test



backward_backup() {
    local conti=$1
    local drct
    drct="$(pwd)"

    # Check if the directory exists
    if [[ -d "$drct/$conti" ]]; then
        if [[ -z "$conti" ]]; then
        echo "backward_backup  <folder_name>"
        return 1
        else
        # Find the highest existing POSCAR-N
        local i=0
        while [[ -e "$drct/POSCAR-$i" ]]; do
            ((i++))
        done

        # Shift POSCAR-N → POSCAR-(N+1) in reverse order
        while (( i > 0 )); do
                echo $i
                echo "$drct/POSCAR-$i"
                j=$((i-1))
                echo "$drct/POSCAR-$j to $drct/POSCAR-$((j+1))"
                mv "$drct/POSCAR-$j" "$drct/POSCAR-$((j+1))"
                mv "$drct/OUTCAR-$j" "$drct/OUTCAR-$((j+1))"
                mv "$drct/OSZICAR-$j" "$drct/OSZICAR-$((j+1))"
                mv "$drct/vasprun-$j.xml" "$drct/vasprun-$((j+1)).xml"
            ((i--))
        done

        # Copy POSCAR to POSCAR-0
        echo "Copying to $drct/$conti"
        echo "$drct/$conti/POSCAR to $drct/$conti/POSCAR-0"
        cp "$drct/$conti/POSCAR" "$drct/$conti/POSCAR-0"
        cp "$drct/$conti/OUTCAR" "$drct/$conti/OUTCAR-0"
        cp "$drct/$conti/OSZICAR" "$drct/$conti/OSZICAR-0"
        cp "$drct/$conti/vasprun.xml" "$drct/$conti/vasprun-0.xml"

        cp $drct/* "$drct/$conti"
        fi
    else
        echo "Given folder does not exist: $drct/$conti"
    fi
}

#backward_backup ".."

create_XDATCAR_using_CONTCARs() {
for dir in "$@";
do
elem_num=$(sed -n '7p' "$dir/CONTCAR")
line_num=$(echo $elem_num 8 | tr ' ' '+' | bc)
head -n "$line_num" "$dir/CONTCAR" >> XDATCAR.vasp
done
}

#reate_XDATCAR_using_CONTCARs single_Fe_4/ single_Fe_6/ dimer_Fe_13/

create_XDATCAR_using_POSCARs() {
for dir in "$@";
do
elem_num=$(sed -n '7p' "$dir/POSCAR")
line_num=$(echo $elem_num 8 | tr ' ' '+' | bc)
head -n "$line_num" "$dir/POSCAR" >> XDATCAR.vasp
done
}

#create_XDATCAR_using_POSCARs single_Fe_4/ single_Fe_6/ dimer_Fe_13/


relative_E0() {
    ref_energy=$(grep "TOTEN" "$1/OUTCAR" | tail -n 1 | awk '{print $5}')
    echo
    printf "Reference: %-30s -> %12.6f eV\n" "$1" "$ref_energy"

    echo
    printf "%-50s %20s eV\n" "System" "Relative_Energy_(ΔE)"
    for file in "$@"; do
        energy=$(grep "TOTEN" "$file/OUTCAR" | tail -n 1 | awk '{print $5}')
        relative=$(echo "$energy - $ref_energy" | bc -l)
        printf "%-50s %12.6f\n" "$file" "$relative"
    done
}

#relative_E0 "$@"
## To see the explain of $@ and $* see: https://unix.stackexchange.com/questions/129072/whats-the-difference-between-and


get_mag_os() {
    for folder in "$@"; do
        oszicar_path="$folder/OSZICAR"
        if [ -f "$oszicar_path" ]; then
            mag_os=$(grep "F=" "$oszicar_path" | head -n 1)
            echo -e "$folder:\tmag_os: $mag_os"
        else
            echo -e "$folder:\t\e[31mOSZICAR not found\e[0m"
        fi
    done
}


get_mag_rlx() {
    for folder in "$@"; do
        vaspout_path="$folder/vasp.out"

        if [ -f "$vaspout_path" ]; then
            mag_rlx=$(grep "mag" "$vaspout_path" | tail -n 1)
            echo -e "$folder:\tmag_rlx: $mag_rlx"
        else
            echo -e "$folder:\t\e[31mvasp.out not found\e[0m"
        fi
    done
}


#Note the elems is array as there are spaces.
# which is equivalent to:
#  elems=$(sed -n '6p' POSCAR)
#  nums=$(sed -n '7p' POSCAR)
#  elms=( $elems )
#  nums=( $nums )
#############################################

#Note the elems is array as there are spaces.
# which is equivalent to:
#  elems=$(sed -n '6p' POSCAR)
#  nums=$(sed -n '7p' POSCAR)
#  elms=( $elems )
#  nums=( $nums )
#############################################


vasp_job_status() {
    local path status0 energy0 elems nums formula i
    #local drct=$(pwd)

    #echo -e "S.N.   Folder                              Job-status                       Energy"
    #echo -e "----------------------------------------------------------------------------------"

    for path in "$@"; do
        #cd "$drct/$i" || continue

        if grep -q 'User time' "$path/OUTCAR" 2>/dev/null; then
            status0="Done"
            energy0=$(grep "TOTEN" "$path/OUTCAR" | tail -n 1 | awk '{print $5}')
            elems=( $(sed -n '6p' $path/POSCAR) )
            nums=( $(sed -n '7p' $path/POSCAR) )
            formula=""
            for i in "${!elems[@]}"; do
                formula+="${elems[i]}${nums[i]}"
            done
        else
            status0="Not done"
            energy0="Not calculated"
        fi

        printf "Path:%-35s Stat:%-25s Energy:%-25s Formula:%-25s Name:\n" "$path" "$status0" "$energy0" "$formula"
    done
}

#vasp_job_status "$@"  Note: $@ are folders, not files.


vasp_energy_without_status() {
    local path=$1
    local status0 energy0 elems nums formula i
    #local drct=$(pwd)

    #echo -e "S.N.   Folder                              Job-status                       Energy"
    #echo -e "----------------------------------------------------------------------------------"

        #cd "$drct/$i" || continue

        if [[ -f "$path/OUTCAR" ]]; then
            energy0=$(grep "TOTEN" "$path/OUTCAR" | tail -n 1 | awk '{print $5}')
            elems=( $(sed -n '6p' $path/POSCAR) )
            nums=( $(sed -n '7p' $path/POSCAR) )
            formula=""
            for i in "${!elems[@]}"; do
                formula+="${elems[i]}${nums[i]}"
            done

            printf "Path:%-35s Energy:%-25s Formula:%-25s Name:\n" "$path" "$energy0" "$formula"
        else
                echo "OUTCAR is not present"
        fi
}

final_outcar_path () {
    local dir1 dir2 drct0

    dir1="$1"
    dir2="$2"

    declare -n final_dir="$dir2"

    drct0="$dir1"

    # Walk down conti/conti/... chain
    while [[ -d "$drct0/conti" ]]; do
        drct0="$drct0/conti"
    done

    if [[ ! -f "$drct0/OUTCAR" ]]; then
      drct0=$(awk '/SCRATCH DIR:/ {print $3; exit}' $drct0/*.o*)
    fi

    final_dir="$drct0"

}



#vasp_job_status() {
#    #local drct=$(pwd)
#    local sn=1
#
#    #echo -e "S.N.   Folder                              Job-status                       Energy"
#    #echo -e "----------------------------------------------------------------------------------"
#
#    for i in "$@"; do
#        #cd "$drct/$i" || continue
#
#        if grep -q 'User time' "$i/OUTCAR" 2>/dev/null; then
#            status0="Done"
#            energy0=$(grep "TOTEN" "$i/OUTCAR" | tail -n 1 | awk '{print $5}')
#        else
#            status0="Not done"
#            energy0="Not calculated"
#        fi
#
#        printf "Path:%-35s Stat:%-25s Energy:%-25s Name:\n" "$i" "$status0" "$energy0"
#        ((sn++))
#    done
#}

## To see the explain of $@ and $* see: https://unix.stackexchange.com/questions/129072/whats-the-difference-between-and

vasp_job_status_combined() {
  local input=()
  # Read input: either from args or stdin
  if (( $# > 0 )); then   # replacing this [[ -t 0 && "$#" -ne 0 ]] with (( $# > 0 ))
    input=("$@")
  else
    # Read from stdin into array
    mapfile -t input
  fi

  echo -e "S.N.   Folder                              Job-status                       Energy"
  echo -e "----------------------------------------------------------------------------------"

  for inp in "${input[@]}"; do
     if [ -f "$inp" ]; then
        new_inp=$(dirname "$inp")
     else
        new_inp=$inp
     fi
     if grep -q 'User time' "$new_inp/OUTCAR" 2>/dev/null; then
       status0="Done"
       energy0=$(grep "TOTEN" "$new_inp/OUTCAR" | tail -n 1 | awk '{print $5}')
       elems=( $(sed -n '6p' $new_inp/POSCAR) )
       nums=( $(sed -n '7p' $new_inp/POSCAR) )
       formula=""
       for i in "${!elems[@]}"; do
           formula+="${elems[i]}${nums[i]}"
       done
     else
       status0="Not done"
       energy0="Not calculated"
     fi

     printf "Path:%-35s Stat:%-25s Energy:%-25s Formula:%-25s Name:\n" "$new_inp" "$status0" "$energy0" "$formula"
  done
}

#vasp_job_status_combined ZPE  ZPE0  ZPE_all  ZPE_mag-2/KS ZPE_mag-2/catKS
#echo -e "ZPE\nZPE0\nZPE_all\nZPE_mag-2/KS\nZPE_mag-2/catKS" | vasp_job_status_combined


scf_convergence() {
    echo -e "System\t\t\tSCF Status"
    echo "-------------------------------"

    for folder in "$@"; do
            if [ ! -f $folder/INCAR ] || [ ! -f $folder/OSZICAR ]; then
                echo -e "$folder\t\t\e[1;31mMissing INCAR or OSZICAR\e[0m"
                continue
            fi

            nelm_incar_line=$(grep "NELM" $folder/INCAR)
            if [[ -z "$nelm_incar_line" ]]; then
                nelm_in=60
            else
                nelm_in=$(echo "$nelm_incar_line" | awk -F '=' '{print $2}' | tr -d ' ')
            fi

            nelm_os=$(grep -w -B 1 "1 F=" $folder/OSZICAR | head -n 1 | awk '{print $2}')

            if [[ -z "$nelm_os" ]]; then
                echo -e "$folder\t\t\e[1;31mNot completed SCF\e[0m"
            else
                if [[ $nelm_in -gt $nelm_os ]]; then
                    echo -e "$folder\t\t\e[32mConverged\e[0m"
                else
                    echo -e "$folder\t\t\e[31mNot converged\e[0m"
                fi
            fi

    done
}

#scf_convergence polysulfides/S8/ZPE  polyabosrbtion/Ni/K2S/ZPE


scf_convergence_combined() {
    # Read input: either from args or stdin
    if [[ -t 0 && "$#" -ne 0 ]]; then
      input=("$@")
    else
      # Read from stdin into array
      mapfile -t input
    fi


    echo -e "System\t\t\tSCF Status"
    echo "-------------------------------"

    for file_folder in "${input[@]}"; do
            if [ -f "$file_folder" ]; then
               folder=$(dirname "$file_folder")
            else
               folder=$file_folder
            fi
            if [ ! -f $folder/INCAR ] || [ ! -f $folder/OSZICAR ]; then
                echo -e "$folder\t\t\e[1;31mMissing INCAR or OSZICAR\e[0m"
                continue
            fi

            nelm_incar_line=$(grep -E '^[^#]*\bNELM\b' $folder/INCAR)
            if [[ -z "$nelm_incar_line" ]]; then
                nelm_in=60
            else
                nelm_in=$(echo "$nelm_incar_line" | awk -F '=' '{print $2}' | awk '{print $1}' | tr -d ' ')
            fi

            nelm_os=$(grep -w -B 1 "1 F=" $folder/OSZICAR | head -n 1 | awk '{print $2}')

            if [[ -z "$nelm_os" ]]; then
                echo -e "$folder\t\t\e[1;31mNot completed SCF\e[0m"
            else
                if [[ $nelm_in -gt $nelm_os ]]; then
                    echo -e "$folder\t\t\e[32mConverged\e[0m"
                else
                    echo -e "$folder\t\t\e[31mNot converged\e[0m"
                fi
            fi

    done
}

#scf_convergence_combined /mnt/research/barone/singh21m/new_KS/new2/melon/K2S/scf/DONE
#scf_convergence_combined /mnt/research/barone/singh21m/new_KS/new2/melon/K2S/scf
#scf_convergence_combined 1_most/ZPE0   1_most/ZPE 1_most 
#echo -e "1_most/ZPE0\n1_most/ZPE\n1_most" | scf_convergence_combined 


#scf_convergence_combined /mnt/research/barone/singh21m/new_KS/new2/melon/K2S/scf/DONE
#scf_convergence_combined /mnt/research/barone/singh21m/new_KS/new2/melon/K2S/scf
#scf_convergence_combined 1_most/ZPE0   1_most/ZPE 1_most 
#echo -e "1_most/ZPE0\n1_most/ZPE\n1_most" | scf_convergence_combined 


#scf_convergence() {
#nelm_incar_line=$(grep "NELM" INCAR)
#if [[ -z "$nelm_incar_line" ]]; then
#    nelm_in=60  # Default values of NELM
#else
#nelm_in=$(echo $nelm_incar_line | awk -F '=' '{print $2}')
#fi
#
#nelm_os=$(grep -w -B 1 "1 F=" OSZICAR | head -n 1 | awk '{print $2}')
#echo $nelm_in, $nelm_os
#if [[ -z $nelm_os ]];then
#    echo -e "\e[1;31mNot completed SCF.\e[0m"
#else
#    if [[ $nelm_in -gt $nelm_os ]]; then
#        echo -e "\e[32mConverged.\e[0m"
#    else
#        echo -e "\e[31mNot converged.\e[0m"
#    fi
#fi
#}


term2conti() {
        term_dir="$1" # foldername of TERMINATED dir.
        submit_dir=$(dirname $term_dir)  # Note this is not initial submit dir. It can be conti.
        cp $term_dir/CONTCAR $submit_dir
        cp $term_dir/OUTCAR $submit_dir
        cp $term_dir/OSZICAR $submit_dir
        cp $term_dir/XDATCAR $submit_dir
        cp $term_dir/vasp.out $submit_dir

        # copying any subdirectory present in TERMINATED dir.
        cp -r $term_dir/*/ $submit_dir 2>/dev/null

        # printing to delete file
        echo "Need to delete: " $term_dir

        # creating conti dir if it is not present already either in submit dir or TERMINATED dir.
        if [ ! -d "$submit_dir/conti" ]; then
        mkdir $submit_dir/conti
        cp $submit_dir/CONTCAR $submit_dir/conti/POSCAR
        cp $submit_dir/POTCAR $submit_dir/conti
        cp $submit_dir/KPOINTS $submit_dir/conti
        cp $submit_dir/INCAR $submit_dir/conti
        cp $submit_dir/job.sh $submit_dir/conti
        fi
}
#term2conti $drct/graphene0/TERMINATED_bK2S_graphene_61429851_2025-09-16

fail2conti() {
        ## Note this function is same as term2conti().

        fail_dir="$1" # foldername of FAILED dir.
        submit_dir=$(dirname $fail_dir)  # Note this is not initial submit dir. It can be conti.
        cp $fail_dir/CONTCAR $submit_dir
        cp $fail_dir/OUTCAR $submit_dir
        cp $fail_dir/OSZICAR $submit_dir
        cp $fail_dir/XDATCAR $submit_dir
        cp $fail_dir/vasp.out $submit_dir

        # copying any subdirectory present in TERMINATED dir.
        cp -r $fail_dir/*/ $submit_dir 2>/dev/null

        # printing to delete file
        echo "Need to delete: " $fail_dir

        # creating conti dir if it is not present already either in submit dir or TERMINATED dir.
        if [ ! -d "$submit_dir/conti" ]; then
        mkdir $submit_dir/conti

        cp $submit_dir/CONTCAR $submit_dir/conti/POSCAR
        cp $submit_dir/POTCAR $submit_dir/conti
        cp $submit_dir/KPOINTS $submit_dir/conti
        cp $submit_dir/INCAR $submit_dir/conti
        cp $submit_dir/job.sh $submit_dir/conti
        fi
}
#fail2conti $drct/graphene0/FAILED_bK2S_graphene_61429851_2025-09-16




#term2conti $drct/Li2S4/TERMINATED_mCo_Li2S4_64771360_2025-11-26
#term2conti $drct/Li2S2/TERMINATED_mCo_Li2S2_64771358_2025-11-26
#term2conti $drct/Li2S6/TERMINATED_mCo_Li2S6_64771361_2025-11-26
#completed_conti_2_initial_submit_dir  $drct/Li2S4/conti/
#completed_conti_2_initial_submit_dir  $drct/Li2S2/conti/
#completed_conti_2_initial_submit_dir  $drct/Li2S6/conti/

conti_job() {
    local drct
    drct=$(pwd)
    mkdir -p "$drct/conti"
    cp CONTCAR "$drct/conti/POSCAR"
    cp POTCAR KPOINTS INCAR job.sh "$drct/conti/"
    echo "Files copied to $drct/conti"
}
term_dirs_build () {
  mapfile -t dirs < <(find "$(pwd)" -type d -name "TERM*")
  export IDX=0
  echo "Found ${#dirs[@]} directories"
}

restart_job() {
    local drct
    drct=$(pwd)
    mkdir -p "$drct/restart"
    if [[ -f "POSCAR_init" ]];then
    cp POSCAR_init "$drct/restart/POSCAR"
    else
    cp POSCAR "$drct/restart/POSCAR"
    fi
    cp POTCAR KPOINTS INCAR job.sh "$drct/restart/"
    echo "Files copied to $drct/restart"
}

scf_job() {
    local drct
    drct=$(pwd)
    mkdir -p "$drct/scf"
    cp CONTCAR "$drct/scf/POSCAR"
    cp POTCAR KPOINTS job.sh "$drct/scf/"
    sed -i 's/--job-name[[:space:]]\+/&s/' "$drct/scf/job.sh"
    sed -i 's/--time=[^[:space:]]*/--time=0-04:00:00/' "$drct/scf/job.sh"
    echo "1- Files copied to $drct/scf"
    echo "2- Put INCAR_dos_bader (including LELF tag)"
}


nextdir () {
  IDX=${IDX:-0}

  if [[ -z "${dirs[*]}" ]]; then
    echo "dirs is not defined"
    echo "Run: mapfile -t dirs < <(find ...)"
    return 1
  fi

  if (( IDX >= ${#dirs[@]} )); then
    echo "No more directories"
    unset dirs
    unset IDX
    echo "dirs[] and IDX cleared"
    return
  fi

  cd "${dirs[$IDX]}" || return
  echo "Now in: ${dirs[$IDX]}"

  export IDX=$((IDX + 1))
}


nextdir_var_clean () {
  unset dirs
  unset IDX
  echo "dirs[] and IDX cleared"
}

vasp_steps() {
    local start_dir dir total_steps last_step conti_scratch

    start_dir="${1:-.}"
    dir="$start_dir"
    total_steps=0


    # If both OSZICAR and OSZICAR-* exist
    if [[ -f "$dir/OSZICAR" ]] && compgen -G "$dir/OSZICAR-"* > /dev/null; then
        for osz in OSZICAR*
        do
         echo $osz
        last_step=$(awk '
            $1 ~ /^[0-9]+$/ {step=$1}
            END {print step+0}
        ' "$dir/$osz")
        echo "Found $last_step steps in $osz"
        total_steps=$((total_steps + last_step))
        done

    else
        while [[ -f "$dir/OSZICAR" ]]; do
            # Get last ionic step number from OSZICAR
            last_step=$(awk '
                $1 ~ /^[0-9]+$/ {step=$1}
                END {print step+0}
            ' "$dir/OSZICAR")

            echo "Found $last_step steps in $dir"
            total_steps=$((total_steps + last_step))


            if [[ -d "$dir/conti" ]]; then
                if [[ -f "$dir/conti/OSZICAR" ]]; then
                    dir="$dir/conti"

                else
                    conti_scratch=$(awk '/SCRATCH DIR:/ {print $3; exit}' "$dir/conti"/*.o*)
                    dir="$conti_scratch"
                fi
            else
                break
            fi

        done
    fi

    echo "--------------------------------"
    echo "Total ionic steps = $total_steps"
}

#vasp_steps


vasp_opt_energy() {
    local start_dir dir total_steps last_step conti_scratch

    start_dir="${1:-.}"
    dir="$start_dir"
    total_steps=0


    # If both OUTCAR and OUTCAR-* exist
    if [[ -f "$dir/OUTCAR" ]] && compgen -G "$dir/OUTCAR-"* > /dev/null; then
        #for outc in OUTCAR 
        for outc in $(ls -r OUTCAR*);
        do
        #echo $outc
        grep "e  e" $outc | awk '{print $5}'
        done

    else
        while [[ -f "$dir/OUTCAR" ]]; do
            # Get last ionic step number from OUTCAR
            grep "e  e" "$dir/OUTCAR" | awk '{print $5}'

            if [[ -d "$dir/conti" ]]; then
                if [[ -f "$dir/conti/OUTCAR" ]]; then
                    dir="$dir/conti"

                else
                    conti_scratch=$(awk '/SCRATCH DIR:/ {print $3; exit}' "$dir/conti"/*.o*)
                    dir="$conti_scratch"
                fi
            else
                break
            fi

        done
    fi
}

#vasp_opt_energy


