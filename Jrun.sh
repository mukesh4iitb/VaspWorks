jobids=$(squeue -u $USER -h -o "%i")

echo writing paths in jobpaths.txt.
for job_id in $jobids; do
    path=$(scontrol show job $job_id | grep WorkDir | sed "s/WorkDir=//")
    echo "$job_id   $path"     >> jobpaths.txt
done

echo
echo printing all the job ids

for job in $jobids
do echo -n "$job "
done
echo 


echo 
echo "Resources:"
total_mem=0
total_cpu=0
cn=0

for job in $jobids
do
    mem=$(scontrol show job "$job" | awk '/AllocTRES=/ {match($0, /mem=([0-9]+)G/, arr); print arr[1]}')
    cpu=$(scontrol show job "$job" | awk '/AllocTRES=/ {match($0, /cpu=([0-9]+)/, arr); print arr[1]}')
    name=$(scontrol show job "$job" | awk '/JobName=/ {match($0, /JobName=([^,]*)/, arr); print arr[1]}')
    time=$(scontrol show job "$job" | awk '/TimeLimit=/ {match($0, /TimeLimit=([^ ,]*)/, arr); print arr[1]}')

    # Ensure values are not empty
    mem=${mem:-0}
    cpu=${cpu:-0}

    total_mem=$((total_mem + mem))
    total_cpu=$((total_cpu + cpu))
    ((cn++))

    echo "ID: $job, Memory: ${mem}G, CPUs: $cpu, Name: $name, Time: $time"
done

echo
echo "Total number of jobs: $cn"
echo "Total memory: ${total_mem}G"
echo "Total CPUs: $total_cpu"

