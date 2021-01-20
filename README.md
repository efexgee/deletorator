# sysadmin-file-deletorator
A persistent deletion worker as a simple shell script
## deletorator.sh
Deletes directories or files placed into the current directory while avoiding multiple deletes working on the same directory tree. It is intended to run as multiple, backgrounded instances from the command line.
### Usage
* To launch a single instance
deletorator.sh &
* To launch multiple instances
for i in [1..20]; do
  deletorator.sh &
done

### Operation
* All settings are specified via constants near the top of the script in order to keep things simple.
* When a deletorator is launched it will wait for a random amount of time before checking the work directory to avoid collisions when many instances are launched at the same time
* Each instance will select a random directory in the work directory and move it to its own temp directory before starting the deletion. The 'mv' command is atomic a prevents collisions in the move operation itself but the selection operation can still cause collisions when running large number of instances.
* When an instance has finished deleting it will immediately check for more work. If it finds no work it will wait for a some number of seconds before checking again. For some applications it might make sense to set this delay very low.
* deletorators can be stopped by creating a specific file in either an instance's working directory to stop a single instance or in the deletorator directory to stop all instances:

DELETORATOR/STOP_DELETORATOR          
DELETORATOR/<id>/STOP_ALL_DELETORATORS

* For safety, deletorator will only work on directories with a special, hard-coded name specified by the CHECK_NAME variable (default: TO_BE_DELETED)

### Issues
* ideally it would be a single worker spawning processes but I wanted to be able to list the instances with the 'jobs' command
* does not clean up temp dirs when killed uncleanly
