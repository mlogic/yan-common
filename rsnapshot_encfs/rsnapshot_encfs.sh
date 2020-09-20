#!/usr/bin/env bash
# Do precheck and run backup jobs. This script is supposed to be run
# by run-until-success.sh.
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
if [[ ${DEBUG:-0} -ne 0 ]]; then set -x; fi

# On any unexpected error, notify run_until_sucess to stop retrying.
stop_run_until_success() {
    exit 9
}
trap stop_run_until_success ERR

YAN_COMM="$(dirname $0)/.."
readonly YAN_COMM
LOG_IDENTIFIER=${LOG_IDENTIFIER:-rsnapshot_encfs}
. "${YAN_COMM}/shell/_log.sh"

if [[ $# -eq 0 ]]; then
    cat<< EOF
Usage: $0 config_file <rsnapshot_job>
Example: $0 ~/.config/rsnapshot_encfs_mydataset.config sync daily
EOF
    exit 9
fi
# Source the config file
. "$1"
shift

if (( CHECK_AC_POWER )) && ! on_ac_power; then
    log info "on battery, will retry later"
    exit 1
fi

if [[ -n "${CHECK_NETWORK_MANAGER_NETWORK:-}" ]]; then
  if ! nmcli | grep -q "connected to ${CHECK_NETWORK_MANAGER_NETWORK}"; then
    log info "not on network ${CHECK_NETWORK_MANAGER_NETWORK}, will retry later"
    exit 1
  fi
fi

if [[ -n "${CHECK_PING_HOST:-}" ]]; then
  if ! ping -W 5 -c 1 "${CHECK_PING_HOST}" &>/dev/null; then
    log info "cannot ping ${CHECK_PING_HOST}, will retry later"
    exit 1
  fi
fi

. ${YAN_COMM}/shell/_mutex.sh

if ! _mutex "/var/tmp/${LOG_IDENTIFIER}.lock"; then
  log info "another instance is already running, will retry later"
  exit 1
fi

PLAINTEXT_MOUNT_POINT=`grep "^snapshot_root" "${RSNAPSHOT_CONF_FILE}" | awk '{print $2}'`
# Remove the final /
if [ "${PLAINTEXT_MOUNT_POINT: -1}" = "/" ]; then
  PLAINTEXT_MOUNT_POINT=${PLAINTEXT_MOUNT_POINT::-1}
fi
if ! [ -d "$PLAINTEXT_MOUNT_POINT" ]; then
  log error "Plaintext mount point $PLAINTEXT_MOUNT_POINT doesn't exist or cannot be accessed. Please create it first and check permission."
  exit 9
fi

# The following variable records if it is I (the script) who mounted
# the point. We only unmount it on exit if we mounted it.
I_MOUNTED_PLAINTEXT_MOUNT_POINT=0
cleanup() {
  if (( I_MOUNTED_PLAINTEXT_MOUNT_POINT )); then
    umount "$PLAINTEXT_MOUNT_POINT"
  fi
}
trap cleanup EXIT

if ! stat "$ENCFS" &>/dev/null; then
  log error "Cannot access encfs at ${ENCFS}."
  exit 9
fi

if ! mount | grep -q " on $PLAINTEXT_MOUNT_POINT "; then
  if ! echo "${ENCFS_PASSWORD}" | { encfs --stdinpass "$ENCFS" "$PLAINTEXT_MOUNT_POINT"; } 9>&-; then
    log error "Failed to mount encfs. Abort."
    exit 9
  fi
  I_MOUNTED_PLAINTEXT_MOUNT_POINT=1
fi

for job in $@; do
  # We only check if the last "daily" run fails because it takes the
  # longest time and has the highest chance for fail. "weekly" and
  # "monthly" runs are just several "mv"s and should finish quickly.
  if [[ "${job}" = "daily" ]]; then
    running_file="${DAILY_FINISH_TIMESTAMP_FILE}.running"
    if [[ -f "${running_file}" ]]; then
      log info "Last run failed. Removing daily.1."
      if [[ -d "${PLAINTEXT_MOUNT_POINT}/daily.1" ]]; then
        rm -rf "${PLAINTEXT_MOUNT_POINT}/daily.1"
      else
        log info "Last run failed but couldn't find ${PLAINTEXT_MOUNT_POINT}/daily.1"
      fi
    fi
    touch "${running_file}"
  fi

  # ionice class 3 is idle
  set +e
  nice -n 19 ionice -c 3 rsnapshot -c "${RSNAPSHOT_CONF_FILE}" "${job}"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]] && [[ $rc -ne 2 ]]; then
    log error "rsnapshot job ${job} failed with code $rc. Abort."
    exit 9
  fi

  # Write a finish file for the "sync" task.
  if [[ "${job}" = "sync" ]]; then
    date +"%F %H:%M:%S" > "${SYNC_FINISH_TIMESTAMP_FILE}"
  elif [[ "${job}" = "daily" ]]; then
    date +"%F %H:%M:%S" > "${DAILY_FINISH_TIMESTAMP_FILE}"
    rm "${running_file}"
  fi
done # for job in "$@"

