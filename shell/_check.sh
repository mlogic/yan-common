# Function for check a condition with timeout
# 
# Copyright (c) 2016 Yan Li <yanli@tuneup.ai>. All rights reserved.
# 
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

################################################################################
# Function name: _check
#
# Desc: Runs "cmd" every 0.1 seconds until it succeeds or the timeout is
#       reached
#
# Arguments: timeout cmd
#
# Sample:
#     _check 10 grep "daemon stopped" /var/log/daemon.log
_check()
{
    local TIMEOUT=$1
    shift
    END=$((SECONDS+TIMEOUT))
    while [ $SECONDS -lt $END ]; do
        if "$@"; then
            return
        fi
        sleep 0.1
    done
    echo "Timeout while checking $@"
    exit 254
}

################################################################################
# Function name: assert
#
# Desc: assert the rc of test is 0, otherwise print error message and die
#
# Arguments: error_message test
#
# Sample:
#   assert "arg1 wrong" [[ "${arg1}" == "exp" ]]
#
# TODO:
#   support print error message using the "log" function
assert() {
  local error_message=$1
  shift
  if eval "$@"; then
    return
  else
    echo "${error_message}"
    exit 1
  fi
}
