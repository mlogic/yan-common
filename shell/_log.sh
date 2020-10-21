# Logging functions
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

###############################################################################
# Log to one or more destinations.
# usage: log level message...
# options:
#     level: One of "emerg", "alert", "crit", "err", "warning",
#            "notice", "info", "debug" (see systemd-cat(1)). The
#            destination for a specific level is designated by
#            environment variable LOG_{level}. For instance, LOG_INFO
#            specifies the destination for level info.
#
# The LOG_{level} variable specifies the destination of a level and is a
# space separated list of destinations. Destination can be "stdout",
# "stderr", or "syslog.
#
# For instance, when we have
# LOG_INFO="syslog"
# LOG_WARNING="syslog stdout"
# then we could do
# log info "this goes to syslog only"
# log warning "this goes to both syslog and stdout"
#
# Other variables:
# LOG_IDENTIFIER can be used to specify the name of the program instance.
# LOG_PREFIX specifies the prefix for each log line (except syslog destination).
log() {
  # Convert level to lowercase
  local -r level=${1,,}
  shift
  local -r log_level_var=LOG_${level^^}
  local prefix
  prefix="${LOG_PREFIX:-[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${LOG_IDENTIFIER:-}, ${level}:}"
  for dest in ${!log_level_var:-stdout}; do
    case $dest in
      stdout)
        echo "$prefix $@"
        ;;
      stderr)
        echo "$prefix $@" >&2
        ;;
      syslog)
        echo "$@" | systemd-cat --identifier="${LOG_IDENTIFIER:-}" -p ${level}
        ;;
      *)
        echo "Unknown log dest for level ${level}: ${dest}"
        exit 1
        ;;
    esac
  done
}

die() {
  echo "$@" >&2
  exit 1
}
