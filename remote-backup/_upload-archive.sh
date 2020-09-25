#!/usr/bin/env bash
# Upload archives in the staging area using scp
#
# Copyright (c) 2016-2020, Yan Li <yanli@tuneup.ai>,
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
set -euo pipefail
if [ -n "${DEBUG:-}" ]; then set -x; fi
. "$CONFIG"
. `dirname $0`/../shell/_log.sh

if [ -e $LOCK ]; then
    echo "Lock file exist, exiting: $LOCK"
    exit 3
fi
cleanup() {
    rm -f $LOCK
}
trap cleanup EXIT
echo $$ >$LOCK

# We don't need to copy the index file.
case "${REMOTE_TYPE}" in
    ssh)
	scp -i "$SSH_ID" "${STAGING}"/snapshot-*-*-*-*.zpaq "${REMOTE}:${REMOTE_DIR}"
	;;
    rclone)
	# rclone can only copy one file a time
	for file in "${STAGING}"/snapshot-*-*-*-*.zpaq; do
	    rclone copy "${file}" "${REMOTE}:${REMOTE_DIR}"
	done
	;;
    *)
	err "Unknown REMOTE_TYPE: ${REMOTE_TYPE}"
	exit 3
	;;
esac
