# /bin/bash 

# README
# Run this script by passing four command-line args
#  process name, output directory (deletes existing files in that dir), polling interval and user name 


# Accept three args - pname, o/p dirname, sampling interval 
# Find PIDs for matching pname; loop through all PIDs
pname=$1
# find pid for the process name
opfile=$2
interval=$3
uname=$4
touch $opfile

# Loop/Poll continuously at specified interval $3/$interval 
while true
do

    # Get list of PIDs matching with the 
    pids=`pgrep -u $uname $pname`
    # Get time in unixtimestamp
    nixtime=`date +%s`
    
    # Write nixtime, pid, memory
    # Check if pids exist
    if [ -n "${pids}" ]; then
        # Iterate through pids
        # Start-Of Write memory for running pids
        for pid in `echo ${pids[@]}`
        do
            mem=`pmap  ${pid} | grep total | awk ' { print $2 } '`
            echo  "$nixtime, ${pid}, ${mem}" | tee ${opfile}
        done    
        # End-Of Write memory for running pids
    else
        echo "No matching processes/PIDs found"
    fi

sleep $interval
done
# End-Of while loop

