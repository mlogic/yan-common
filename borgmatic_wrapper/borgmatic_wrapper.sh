#!/usr/bin/env bash
# Do precheck and run borgmatic backup jobs. This script is supposed to be run
# by run_until_success.sh.
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
Usage: $0 config_file [args_to_borgmatic]
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

# ionice class 3 is idle
set +e
nice -n 19 ionice -c 3 borgmatic -c "${BORGMATIC_CONF_FILE}" "$@"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  log error "rsnapshot job ${job} failed with code $rc. Abort."
  exit 9
fi

# Write a finish file for the "sync" task.
if [[ -n "${FINISH_TIMESTAMP_FILE:-}" ]]; then
  date +"%F %H:%M:%S" > "${FINISH_TIMESTAMP_FILE}"
fi
