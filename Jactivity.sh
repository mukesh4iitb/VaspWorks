jobids=$(squeue -u $USER -h -o "%i")

echo writing paths in jobpaths.txt.
for job_id in $jobids; do
    path=$(scontrol show job $job_id | grep WorkDir | sed "s/WorkDir=//")
    echo "$job_id   $path"     >> jobpaths.txt
done

echo

for job in $jobids
do 
echo "showing the results of $job"
sstat -j $job
echo 
echo
done

