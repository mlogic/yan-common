# Function for using a pid file as a mutex

# This script was based on a script from http://stackoverflow.com/a/731634, which
# doesn't specify a license so I assume it's in public domain.

# Copyright (c) 2016-2018 Yan Li <yanli@tuneup.ai>. All rights reserved.

# Open a mutual exclusion lock on the file, unless another process already owns one.
#
# If the file is already locked by another process, the operation fails.
# This function defines a lock on a file as having a file descriptor open to the file.
#
# To acquire a lock:
# mutex /var/run/myscript.lock || { echo "Already running." >&2; exit 1; }
#
# This function uses FD 9 to open a lock on the file.  To release the lock, close FD 9:
# exec 9>&-
#
# Caution: all child processes opened by your script would inherit FD 9. So the lock
# would only be considered released when all the child processes are closed. If any
# one of them lingers around, the lock is not released. If this not what you want,
# run the command in a sub-bash shell and release FD 9, such as:
# $ echo XXX | { encfs --stdinpass "$ENCFS" "$PLAINTEXT_MOUNT_POINT"; } 9>&-

_mutex() {
    local file=$1 pid pids 

    exec 9>>"$file"
    { pids=$(fuser -f "$file"); } 2>&- 9>&- 
    for pid in $pids; do
        [[ $pid = $$ ]] && continue

        exec 9>&- 
        return 1 # Locked by a pid.
    done 
}
