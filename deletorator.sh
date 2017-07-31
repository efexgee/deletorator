#/bin/bash

# Intended to run as multiple instances of this
# Does not clean up temp dirs when it's killed
# Does not have a clean way to exit

umask 022

# this is script is scary and will only run inside a dir named this:
CHECK_NAME="TO_BE_DELETED"
SUB_DIR="DELETORATOR"
# using our parent's PID so it matches the jobs -p -l output
PID=$PPID
TEMP_DIR="$SUB_DIR/$PID"
STOP_FILE="$TEMP_DIR/STOP_DELETORATOR"
STOP_ALL_FILE="$SUB_DIR/STOP_ALL_DELETORATORS"
ME="[$PID]"
# random start delay in case many deletorators are started simultaneously
START_JITTER=5  # seconds
# how long to wait if the dir is empty and how much random wait to add to
# reduce the likelihood of collisions
WAIT=300    # seconds
WAIT_JITTER=60  # seconds

path=`pwd`
cur_dir=`basename $path`

# safety check
if [ $cur_dir != $CHECK_NAME ]; then
	echo "$ME The current directory ($path) doesn't match the expected name: $CHECK_NAME"
	exit 2
fi

# create this worker's temp directory
mkdir -p $TEMP_DIR

if [ $? == 0 ]; then
    echo "$ME Created temp dir: $TEMP_DIR"
else
    echo "$ME Failed to create temp dir: $TEMP_DIR. Exiting."
    exit 3
fi

# delay start
# do icky trickery to make random floating point number
start_jitter=$(($START_JITTER * 10))
start_wait=`echo $((RANDOM % $start_jitter + 1 )) | sed 's/\([0-9]\)$/.\1/'`

echo "$ME Waiting $start_wait seconds to start."

sleep $start_wait

echo "$ME Starting. To stop me, create the file '$STOP_FILE'"

# main loop
while true; do
	#echo "$ME Entering main loop."

    if [ -f $STOP_FILE ] || [ -f $STOP_ALL_FILE ]; then

        if [ -f $STOP_FILE ]; then
            stop_file=$STOP_FILE
            # clean up stop file so the rmdir can succeed
            rm $STOP_FILE
        elif [ -f $STOP_ALL_FILE ]; then
            stop_file=$STOP_ALL_FILE
            # we don't clean up the global stop file so others will find it
        fi

        echo "$ME Exiting because stop file found: $stop_file"
        rmdir $TEMP_DIR
        exit 0
    fi

	# exclude the temp dirs and stop file from the deletions
	target=`ls | grep -vi deletorator | sort -R | head -1`
	
	# check the dir for things to delete
	if [ -n "$target" ]; then
		# delete
		echo "$ME Targeting: $target"
		mv $target $TEMP_DIR/ || echo "$ME Failed to move file to temp dir ($TEMP_DIR): $target"
		rm -r --one-file-system --interactive=never $TEMP_DIR/$target || echo "$ME Failed to delete: $TEMP_DIR/$target"
	else
		# directory is empty... wait
		rand_wait=$(($WAIT + $RANDOM % $WAIT_JITTER))
        #TODO print directory
        #TODO or label the $ME by dir/task
		echo "$ME Directory empty. Waiting for $rand_wait secconds."
		sleep $rand_wait
	fi
done

# without a clean way to exit, the script should never get here
echo "$ME Exited main loop. This should never happen."
