#!/bin/bash
# Create/update local backup archvie using zpaq
# 
# Copyright (c) 2016, 2017, Yan Li <yanli@ascar.io>,
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of yan-common nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
set -e -u
if [ -n "${DEBUG:-}" ]; then set -x; fi
. "$CONFIG"

if [ -e $LOCK ]; then
    echo "Lock file exist, exiting: $LOCK"
    exit 3
fi
cleanup() {
    rm -f $LOCK
}
trap cleanup EXIT
echo $$ >$LOCK

if [ ! -d "$STAGING" ]; then
    echo "Staging area $STAGING doesn't exist. Please create it first."
    echo "(I'm not creating it for you in case you written a wrong path.)"
    exit 3
fi

if ! ls "${STAGING}"/*.index.zpaq 1>/dev/null 2>&1; then
    # Create a new full snapshot when there is no index.
    # Remove any residue files from previous failed runs.
    rm -f "$STAGING"/snapshot*
    SNAPSHOT_NAME=snapshot-`date +%Y-%m-%d`
else
    # Reuse the snapshot name from the index file
    SNAPSHOT_NAME=`basename "${STAGING}"/*.index.zpaq | sed -e "s/.index.zpaq//g"`
fi

set +e
nice $ZPAQ a "${STAGING}/${SNAPSHOT_NAME}-????" ${ZPAQOPT[@]} -index "${STAGING}/${SNAPSHOT_NAME}.index.zpaq"
RC=$?
set -e
# zpaq returns 0 on no error, 1 on warnings, and 2 on errors. We only stop on errors.
if [ $RC -ge 2 ]; then
    exit $RC
fi
