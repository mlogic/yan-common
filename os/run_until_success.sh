#!/usr/bin/env bash
# Usage:
# run_until_success.sh [--force] [--stop_rc rc] --retry_gap gap --task_name name -- cmd
# Warning: this tool cannot handle spaces in arguments correctly. Avoid using
# spaces in your command. gap can be written as "30minute" without using space.
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
if [[ ${DEBUG:-0} -ne 0 ]]; then set -x; fi

YAN_COMM="$(dirname $0)/.."
readonly YAN_COMM
. "${YAN_COMM}/shell/_log.sh"
. "${YAN_COMM}/shell/_mutex.sh"

if [[ $# -eq 0 ]]; then
  cat<<EOF
Usage: $0 [options]
Options:
  --force    Create a new at job even when another one of the same command
             exists. Default: not create in this case.
EOF
fi

script_file="$(realpath $0)"
readonly script_file
readonly orig_cmd_opt=("$@")
force=0
stop_rc=0
LOG_INFO=syslog
LOG_ERR="syslog stderr"

# Parse the options
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
        --verbose)
            shift
            LOG_INFO="syslog stderr"
            ;;
        --)
            shift
            break
            ;;
        *)
            log err "Unknown option: $1"
            exit 2
            ;;
    esac
    shift
done
LOG_IDENTIFIER="run_until_success_task_${task_name}"

lock_dir=/var/tmp
if ! [[ -d "${lock_dir}" ]]; then
    mkdir -p "${lock_dir}"
fi
task_lock="${lock_dir}/run_until_success_${task_name}.job"
_mutex "${lock_dir}/run_until_success_${task_name}_mutex.pid" || {
    echo "Another instance is already running. Exiting..."
    exit 1
}
task_identifier_str="# run_until_success: ${task_name}"
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
  log info "Command $@ failed. Queueing it up..."

  # Make sure orig_cmd_opt doesn't have `--force` since we will always
  # add it and having more than one `--force` is just ugly.
  new_cmd_opt=()
  for opt in "${orig_cmd_opt[@]}"; do
    if [[ "$opt" != "--force" ]]; then
      new_cmd_opt+=("$opt")
    fi
  done

  at_output_file="$(mktemp)"
  # We use `--force` to force create our next job when this process is
  # still running.
  set +e
  # Don't double quote `${new_cmd_opt[@]}`, because that would make
  # them a single argument in here document.
  cat<<EOF | at NOW + "${retry_gap}" 2>"${at_output_file}"
${task_identifier_str}
"${script_file}" --force ${new_cmd_opt[@]}
EOF
  if [[ $? -ne 0 ]]; then
    log err "Failed to queue the next job:"
    cat "${at_output_file}">&2
    exit 3
  fi
  job=$(grep "^job " "${at_output_file}" | cut -d' ' -f2)
  echo $job >"${task_lock}"
fi
