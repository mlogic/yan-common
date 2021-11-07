#!/usr/bin/env bash
# Clean up remote snapshots
#
# Copyright (c) 2016-2021, Yan Li <yanli@tuneup.ai>,
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
. `dirname $0`/_support_funcs.sh

if [ $REMOTE_FULL_SNAPSHOTS_TO_KEEP ]; then
    case "${REMOTE_TYPE}" in
	ssh)
	    REMOTE_SS="$(ssh -i "$SSH_ID" "$REMOTE" ls "${REMOTE_DIR}/*")"
	    ;;
	rclone)
	    REMOTE_SS="$(rclone ls "${REMOTE}:${REMOTE_DIR}" | awk '{print $2}')"
	    ;;
	*)
	    err "Unknown REMOTE_TYPE: ${REMOTE_TYPE}"
	    exit 3
	    ;;
    esac
    SS_TO_DEL="$(list-snapshots-to-del "$REMOTE_SS" $REMOTE_FULL_SNAPSHOTS_TO_KEEP)"
    if [ -n "$SS_TO_DEL" ]; then
	case "${REMOTE_TYPE}" in
	    ssh)
		echo "$SS_TO_DEL" | xargs ssh -i "$SSH_ID" "$REMOTE" rm
		;;
	    rclone)
		for file in ${SS_TO_DEL}; do
		    rclone delete "${REMOTE}:${REMOTE_DIR}" --include="${file}"
		done
		;;
	    *)
		err "Unknown REMOTE_TYPE: ${REMOTE_TYPE}"
		exit 3
		;;
	esac
    fi
fi
