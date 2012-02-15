# /bin/bash 

# README
# Run this script by passing four command-line args
#  process name, output directory (deletes existing files in that dir), polling interval and user name 


# Accept three args - pname, o/p dirname, sampling interval 
# Find PIDs for matching pname; loop through all PIDs
ppid=$1
opfile="$ppid.txt"
touch $opfile

# Loop/Poll continuously at specified interval $3/$interval 
while true
do

    # Get list of PIDs matching with the 
    pids=`ps -o pid h --ppid $ppid`
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
            echo  "$nixtime, ${pid}, ${mem}" >> ${opfile}
        done    
        # End-Of Write memory for running pids
    else
        echo "No matching processes/PIDs found"
    fi

sleep 1
done
# End-Of while loop

