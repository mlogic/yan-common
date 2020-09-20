#!/usr/bin/env bash
# Usage:
# run-until-success.sh [--force] [--stop_rc rc] --retry_gap gap --task_name name -- cmd
#
# TODO:
# 1. test cases
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

YAN_COMM="$(dirname $0)/.."
readonly YAN_COMM
. "${YAN_COMM}/shell/_log.sh"
. "${YAN_COMM}/shell/_mutex.sh"

readonly orig_cmd_opt=("$@")
force=0
stop_rc=0

while :; do
    case $1 in
        --force)
            force=1
            ;;
        --stop_rc)
            shift
            stop_rc=$1
            ;;
        --retry_gap)
            shift
            retry_gap=$1
            ;;
        --task_name)
            shift
            task_name=$1
            ;;
        --)
            shift
            break
            ;;
        *)
            log error "Unknown option: $1"
            exit 2
            ;;
    esac
    shift
done

lock_dir=/var/tmp/run-until-success
if ! [[ -d "${lock_dir}" ]]; then
    mkdir -p "${lock_dir}"
fi
task_lock="${lock_dir}/${task_name}.job"
_mutex "${lock_dir}/${task_name}_mutex.pid" || {
    echo "Another instance is already running. Exiting..."
    exit 1
}
task_identifier_str="# run-until-success: ${task_name}"
if [[ -f "${task_lock}" ]]; then
  job="$(cat "${task_lock}")"
  job_cmd_file="$(mktemp)"
  if at -c "$job" >"${job_cmd_file}"; then
    # make sure the job has our task identifier
    if grep -q "${task_identifier_str}" "${job_cmd_file}"; then
      # task is already queued
      if ! (( force )); then
        exit 0
      fi
    fi
  fi
fi

# Remove any stale lock
rm -f "${task_lock}"

set +e
"$@"
rc=$?
set -e

if [[ $rc -ne 0 ]] && [[ $rc -ne $stop_rc ]]; then
    echo "Command $@ failed. Queueing it up..."
    at_output_file="$(mktemp)"
    cat<<EOF | at NOW + "${retry_gap}" 2>"${at_output_file}"
${task_identifier_str}
"$0" --force "${orig_cmd_opt[@]}"
EOF
    job=$(grep "^job " "${at_output_file}" | cut -d' ' -f2)
    echo $job >"${task_lock}"
fi
