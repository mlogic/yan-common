#!/usr/bin/env bash
# Test cases for fileset_par2.py that need sudo
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

sudo_fileset_par2() {
  local data_dir=$1
  shift 1
  pushd "${data_dir}" >/dev/null
  if [[ ${DEBUG:-0} -ne 0 ]]; then EXTRA_ARGS=('-v'); else EXTRA_ARGS=(); fi
  find . | sudo "${YAN_COMM}/os/fileset_par2.py" "$@" "${EXTRA_ARGS[@]}"
  rc=$?
  popd >/dev/null
  return $rc
}

EFFECTIVE_UID=$(id -u)
readonly EFFECTIVE_UID
if [[ $EFFECTIVE_UID -eq 0 ]]; then
  echo "This test must be started as a non-root user. Exiting..."
  exit 1
fi
if [[ $(stat -c "%u" test_fileset_par2_data/2.txt) -eq 0 ]]; then
  echo "The owner of files in test_fileset_par2_data must not be root. Exiting..."
  exit 1
fi
TC_NAME="${0}:test_generating_par2_files_in_hidden_par2_dir_as_root"
tmp_par2_data_dir="$(mktemp -d)"
rsync -a test_fileset_par2_data/ "${tmp_par2_data_dir}/"
sudo_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
assert "The par2 file's owner is not set correctly" [[ $(stat -c "%u" "${tmp_par2_data_dir}/.par2/2.txt.par2") -eq $EFFECTIVE_UID ]]
echo "PASS: ${TC_NAME}"
