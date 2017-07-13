#/bin/bash

# Intended to run as multiple instances of this
# Does not clean up temp dirs when it's killed
# Does not have a clean way to exit

# this is script is scary and will only run inside a dir named this:
CHECK_NAME="TO_BE_DELETED"
SUB_DIR="deletorator"
TEMP_DIR="$SUB_DIR/$$"
STOP_FILE="$SUB_DIR/STOP_DELETORATORS"
ME="[$$]"
# how long to wait if the dir is empty and how much random wait to add to
# reduce the likelihood of collisions
WAIT=300
WAIT_JITTER=60
WAIT=10
WAIT_JITTER=5

path=`pwd`
cur_dir=`basename $path`

# safety check
if [ $cur_dir != $CHECK_NAME ]; then
	echo "$ME The current directory ($path) doesn't match the expected name: $CHECK_NAME"
	exit
fi

# create this worker's temp directory
mkdir -p $TEMP_DIR || ( echo "$ME Failed to create temp dir: $TEMP_DIR"; exit )
echo "$ME Created temp dir: $TEMP_DIR"

# main loop
while true; do
	#echo "$ME Entering main loop."

    if [ -f $STOP_FILE ]; then
        echo "$ME Exiting because stop file found: $STOP_FILE"
        exit
    fi

	# exclude the temp dirs from the deletions
	target=`ls | grep -v deletorator | sort -R | head -1`
	
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
