# Function for managing steps

# Copyright (c) 2016-2021 Yan Li <yanli@tuneup.ai>,
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Yan Li nor the names of other contributors
#       may be used to endorse or promote products derived from this
#       software without specific prior written permission.
#
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL YAN LI BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Get our own location.  "${BASH_SOURCE}" can be a symlink, so we
# first get its real dir location, then find it's parent dir.
_YAN_COMM="$(realpath "$(dirname "$(realpath "${BASH_SOURCE}")")/..")"
. ${_YAN_COMM}/shell/_log.sh

if [[ -z "${SCRIPT_NAME:-}" ]]; then
  echo "SCRIPT_NAME must be set before source _step.sh."
  exit 2
fi

# Parse the arguments.
_yc_start_step_arg_seen=0
_yc_continue_last_failed_step=0
for var in "$@"; do
  if (( _yc_start_step_arg_seen )); then
    _yc_start_step="$var"
    readonly _yc_start_step
    _yc_start_step_arg_seen=0
  elif [[ "$var" = "--start_step" ]]; then
    _yc_start_step_arg_seen=1
  elif [[ "$var" = "--continue_last_failed_step" ]]; then
    _yc_continue_last_failed_step=1
  fi
done

if (( _yc_continue_last_failed_step && _yc_start_step )); then
  echo "continue_last_failed_step and start_step cannot both be set"
  exit 2
fi

_YC_CONFIG_DIR="${HOME}/.config/yan_common_step_counters"
readonly _YC_CONFIG_DIR
mkdir -p "${_YC_CONFIG_DIR}"
_YC_LAST_STEP_FILE="${_YC_CONFIG_DIR}/${SCRIPT_NAME}"
readonly _YC_LAST_STEP_FILE

if (( _yc_continue_last_failed_step )); then
  _yc_start_step="$(cat "${_YC_LAST_STEP_FILE}")"
fi

if [[ -z "${_yc_start_step:-}" ]]; then
  # start_step is not used. Start from the first step.
  _yc_start_step_seen=1
  rm "${_YC_LAST_STEP_FILE}"
else
  _yc_start_step_seen=0
fi

################################################################################
# Function name: run_step
#
# Desc: If "--start_step step" is provided on the command line, only
#       run "cmd" if step_name equals the desired step or a previous
#       step with the desired name has run.
#
# Arguments: step_name cmd
#
# Sample:
#     _step "backup" do_backup
run_step() {
  local STEP_NAME=$1
  shift
  if (( _yc_start_step_seen )); then
    echo "$STEP_NAME" >"${_YC_LAST_STEP_FILE}"
    "$@"
  elif [[ "$STEP_NAME" == "${_yc_start_step}" ]]; then
    echo "$STEP_NAME" >"${_YC_LAST_STEP_FILE}"
    _yc_start_step_seen=1
    "$@"
  fi
}

