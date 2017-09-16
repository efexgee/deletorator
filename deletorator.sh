#/bin/bash

# Deletes directories or files placed into the current directory while avoiding
# multiple deletes working on the same directory tree

# Intended to run as multiple instances from the command line, in the background
# Ideally it would be a single worker spawning processes
# Does not clean up temp dirs when it's killed

#TODO why does the target dir get deleted twice? (or try to)
#TODO deletorators should die if the DELETORATOR dir itself is gone
#TODO instead of failing to delete its PID dir when it's gone, check for it first

umask 022

# Because this script is scary will only run inside a dir named this:
# (These directories are created by my 'tombstone' alias
CHECK_NAME="TO_BE_DELETED"

# Define deletorator working directories
SUB_DIR="DELETORATOR"
PID=$PPID                                       # parent pid so it matches jobs -p -l output
TEMP_DIR="$SUB_DIR/$PID"                        # deletorator's working dir

# Define files to stop deletorators
# deletorators only check when they are looking for a new task
# This will not interrupt them
STOP_FILE="$TEMP_DIR/STOP_DELETORATOR"          # to stop a single deletorator
STOP_ALL_FILE="$SUB_DIR/STOP_ALL_DELETORATORS"  # to stop all deletorators

# Prefix for messages to identify who printed it
ME="[$PID]"

# Define timeouts
WAIT=120        # seconds to wait if there is nothing to delete
WAIT_JITTER=60  # wait up to this many additional seconds to avoid collisions
START_JITTER=5  # wait up to this many seconds before starting the first deletion

# grab current dir name
path=`pwd`
cur_dir=`basename $path`

# check that we're in a dir with the correct name to avoid disasters
if [ $cur_dir != $CHECK_NAME ]; then
	echo "$ME The current directory ($path) doesn't match the expected name: $CHECK_NAME"
	exit 2
fi

# create this worker's temp directory (including parents)
mkdir -p $TEMP_DIR

if [ $? == 0 ]; then
    #XXX probably too verbose
    echo "$ME Created temp dir: $TEMP_DIR"
else
    echo "$ME Failed to create temp dir: $TEMP_DIR. Exiting."
    exit 3
fi

# delay initial start
# (icky string trickery to make random floating point number)
start_jitter=$(($START_JITTER * 10))
start_wait=`echo $((RANDOM % $start_jitter + 1 )) | sed 's/\([0-9]\)$/.\1/'`
echo "$ME Waiting $start_wait seconds to start."
sleep $start_wait

echo "$ME Starting. To stop me, create the file '$STOP_FILE'"

# main loop
while true; do
    # check for stop files
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
        #XXX this seems to fail regularly (always?)
        rmdir $TEMP_DIR
        exit 0
    fi

	# exclude the temp dirs and the stop file from the deletions
    # and pick a random entry to delete
    #TODO exclude based on the constant
	target=`ls | grep -vi deletorator | sort -R | head -1`
	
	# check whether we got something to delete
    # this step is subject to race conditions but I think it's unlikely
	if [ -n "$target" ]; then
		# delete
		echo "$ME Targeting: $target"
        # move the directory to our working dir so nobody else grabs it
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

# the script either gets ctrl-c'd or stops because of a stop file
# so it should never get here
echo "$ME Exited main loop. This should never happen."
