# /bin/bash 

# README
# Accept a PID (typically 'root' bash process id) and find out
# memory consumed by the given 'root' process id and it's family.


function memtrack(){ 
  # Accept ppid
  ppid=$1
  # pdet = Process command + Process ID
  pdet=`ps -o cmd h --pid $ppid`.$ppid
  # Record total memory used by the given ppid
  mem=`pmap  ${ppid} | grep total | awk ' { print $2 } '`
  nixtime=`date +%s`
  echo  "$nixtime, ${pdet}, ${mem}" >> ${opfile}
  # Find it's children 
  cids=`ps -o pid h --ppid $ppid`;
  # Recusrive call to memtrack if a child/children are found
  if [ -n "${cids}" ]; then 
    for cid in `echo ${cids[@]}`; 
    do 
      memtrack $cid; 
    done; 
  ## else
    ## echo "No Dynasty"; 
  fi
  ## echo "Stack cleared.."; 
}

# Get shell pid - $PPID
shell_pid=$1
opfile="$shell_pid.txt"
touch $opfile

# Loop/Poll continuously using memtrack
while true
do
  memtrack $shell_pid
sleep 1
done
# End-Of while loop

