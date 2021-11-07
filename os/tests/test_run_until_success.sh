#!/usr/bin/env bash
# Test cases for run_until_success.sh
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
cd "$(dirname "$0")"
YAN_COMM="$(pwd)/../.."
readonly YAN_COMM
. "${YAN_COMM}/shell/_log.sh"
. "${YAN_COMM}/shell/_check.sh"

# Test a task is repeated after failed:
# Don't generate the worker log file yet. Let the worker generate it
# so we know if the worker has been called.
declare -r TC_NAME="${0}:test_repeating_failed_task"
WORKER_LOG_FILE="$(mktemp --dry-run)"
readonly WORKER_LOG_FILE

# Use a random task name to prevent collision
chronic ../run_until_success.sh --retry_gap 1minute --task_name test_task_${RANDOM} -- \
        ./_test_run_until_success_worker.sh arg1 arg2 arg3 "$WORKER_LOG_FILE"
val_from_worker=$(cat "${WORKER_LOG_FILE}")
assert "FAILED: ${TC_NAME}: worker is not called for first run" [[ $val_from_worker -eq 0 ]]
# Sleep a little longer than 1 minute to give at job some time to finish
echo "Waiting for worker to finish. This needs about 65 seconds..."
sleep 65
val_from_worker=$(cat "${WORKER_LOG_FILE}")
assert "FAILED: ${TC_NAME}: worker is not called for subsequent run" [[ $val_from_worker -gt 0 ]]

echo "PASS: ${TC_NAME}"

# TODO: test stop_rc
