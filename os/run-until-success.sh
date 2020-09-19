#!/usr/bin/env bash
# Usage:
# run-until-success.sh [--force] [--stop_rc rc] --retry_gap gap --task_name name -- cmd
#
# TODO:
# 1. test cases

. "${YAN_COMMON}/shell/_base.sh"
. "${YAN_COMMON}/shell/_mutex.sh"

set -euo pipefail
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
            die "unknown option"
            ;;
    esac
    shift
done

lock_dir=/var/tmp/run-until-success
task_lock="${lock_dir}/${task_name}.job"
_mutex "${lock_dir}/${task_name}_mutex.pid" || {
    echo "Another instance is already running. Exiting..."
    exit 1
}
task_identifier_str="# run-until-success: ${task_name}"
if ! [[ -d "${lock_dir}" ]]; then
    mkdir "${lock_dir}"
else
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
    job=$(cat "${at_output_file}" | cut -d' ' -f2)
    echo $job >"${task_lock}"
fi
