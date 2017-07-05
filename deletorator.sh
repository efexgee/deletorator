#1/bin/bash

CHECK_NAME="TO_BE_DELETED"
TEMP_DIR="deletorator/$$"
ME="[$$]"
WAIT=15
WAIT_JITTER=5

path=`pwd`
cur_dir=`basename $path`

if [ $cur_dir != $CHECK_NAME ]; then
	echo "$ME The current directory ($path) doesn't match the expected name: $CHECK_NAME"
	exit
fi

mkdir -p $TEMP_DIR || ( echo "$ME Failed to create temp dir: $TEMP_DIR"; exit )
echo "$ME Created temp dir: $TEMP_DIR"

while true; do
	#echo "$ME Entering main loop."
	target=`ls | grep -v deletorator | sort -R | head -1`
	
	if [ -n "$target" ]; then
		# delete
		echo "$ME Targeting: $target"
		mv $target $TEMP_DIR/ || echo "$ME Failed to move file to temp dir ($TEMP_DIR): $target"
		rm -r --one-file-system --interactive=never $TEMP_DIR/$target || echo "$ME Failed to delete: $TEMP_DIR/$target"
	else
		# directory is empty... wait
		rand_wait=$(($WAIT + $RANDOM % $WAIT_JITTER))
		echo "$ME Directory empty. Waiting for $rand_wait secconds."
		sleep $rand_wait
	fi
done

echo "$ME Exited main loop. This should never happen."
