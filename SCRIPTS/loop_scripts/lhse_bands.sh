vaspworks_location=$(which vasp_inp.sh)
vaspworks_dir=$(dirname $vaspworks_location)

source $vaspworks_dir/UTILS/vasp_inp_functions.sh

echo "Running HSE-band calculations..."
# Add your HSE-band command here

## Call the functions
#creating_potcar_system
#creating_kpoints_system
#copying_jobs_script
##replace_add_INCAR_tag  INCAR1 INCAR2 ENCUT
