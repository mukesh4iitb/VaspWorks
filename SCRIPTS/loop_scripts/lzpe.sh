vaspworks_location=$(which vasp_inp.sh)
vaspworks_dir=$(dirname $vaspworks_location)

source $vaspworks_dir/UTILS/vasp_inp_functions.sh

drct=$(pwd)

echo "copying INCAR_ZPE_MJ"
cp $vaspworks_dir/DATA/INCAR_ZPE_MJ $drct
echo "copying lselective_dynamics.py"
cp $vaspworks_dir/PYTHONS/loop_pythons/lselective_dynamics.py $drct
echo "copying lINCAR_mag.py"
cp $vaspworks_dir/PYTHONS/loop_pythons/lINCAR_mag.py $drct

#cp CONTCAR $drct/ZPE/POSCAR
#cp POTCAR $drct/ZPE/POTCAR
#cp KPOINTS $drct/ZPE/KPOINTS
#replace_add_INCAR_tag $drct/INCAR_mag $drct/ZPE/INCAR MAGMOM
#replace_add_INCAR_tag $drct/INCAR $drct/ZPE/INCAR ENCUT EDIFF EDIFFG IVDW
#python3 lselective_dynamics.py
#mv $drct/$i/ZPE/POSCAR $drct/$i/ZPE/POSCAR_rlx.vasp
#mv $drct/$i/ZPE/POSCAR_Selective.vasp $drct/$i/ZPE/POSCAR

