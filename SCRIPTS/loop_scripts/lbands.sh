vaspworks_location=$(which vasp_inp.sh)
vaspworks_dir=$(dirname $vaspworks_location)

source $vaspworks_dir/UTILS/vasp_inp_functions.sh

echo "bands input (INCAR_band):"
cp  $vaspworks_dir/DATA/INCAR_band INCAR_band

## Call the functions
#creating_potcar_system
#creating_kpoints_system
#copying_jobs_script
##replace_add_INCAR_tag  INCAR1 INCAR2 ENCUT

