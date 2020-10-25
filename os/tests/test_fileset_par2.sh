#!/usr/bin/env bash
# Test cases for fileset_par2.py
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
cd "$(dirname "$0")"
YAN_COMM="$(pwd)/../.."
readonly YAN_COMM
. "${YAN_COMM}/shell/_log.sh"
. "${YAN_COMM}/shell/_check.sh"

run_fileset_par2() {
  local data_dir=$1
  shift 1
  pushd "${data_dir}" >/dev/null
  if [[ ${DEBUG:-0} -ne 0 ]]; then EXTRA_ARGS=('-v'); else EXTRA_ARGS=(); fi
  find . | "${YAN_COMM}/os/fileset_par2.py" "$@" "${EXTRA_ARGS[@]}"
  rc=$?
  popd >/dev/null
  return $rc
}

TC_NAME="${0}:test_generating_par2_files_in_separate_par2_dir"
tmp_par2_dir="$(mktemp -d)"
run_fileset_par2 test_fileset_par2_data --par2_dir "${tmp_par2_dir}"
diff -Nur "${tmp_par2_dir}" "test_fileset_par2_expected"
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:test_verifying_par2_files"
run_fileset_par2 test_fileset_par2_data --par2_dir "${tmp_par2_dir}"
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:test_generating_par2_files_in_hidden_par2_dir"
tmp_par2_data_dir="$(mktemp -d)"
rsync -a test_fileset_par2_data/ "${tmp_par2_data_dir}/"
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
diff -Nur "${tmp_par2_data_dir}/.par2" "test_fileset_par2_expected"
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:test_verifying_par2_files"
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
diff -Nur "${tmp_par2_data_dir}/.par2" "test_fileset_par2_expected"
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:test_corrupted_file"
# Corrupt this file
echo "corrupted_file" > "${tmp_par2_data_dir}/2.txt"
# Then touch the par2 file so it's newer than the corrupted file, this should
# cause fileset_par2 to think the file content is corrupted.
sleep 1
touch "${tmp_par2_data_dir}/.par2/2.txt.par2"
set +e
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
assert "fileset_par2 failed to detect the corrupted file" [[ $? -ne 0 ]]
set -e
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:test_updating_file"
# Now change the mtime of 2.txt and update the par2, to make sure 2.txt.par2
# is changed.
touch "${tmp_par2_data_dir}/2.txt"
# First run with no-update mode
tmp_out="$(mktemp)"
set +e
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir --no_update &>"${tmp_out}"
assert "no-update mode: failed to detect changed file" [[ $? -eq 2 ]]
assert_in_file "no-update mode: failed to detect message 'CHANGED FILE'" "NO-UPDATE MODE, SKIPPED" "${tmp_out}"
set -e
# There should be no change to par2 files
diff -Nur "${tmp_par2_data_dir}/.par2" test_fileset_par2_expected

# Now run it again to actually update the par2 files
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
set +e
diff "${tmp_par2_data_dir}/.par2/2.txt.par2" test_fileset_par2_expected/2.txt.par2 >/dev/null
assert "2.txt.par2 is not updated" [[ $? -ne 0 ]]
set -e
# Restore the old 2.txt and update par2 again
cp test_fileset_par2_data/2.txt "${tmp_par2_data_dir}"
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
# Now 2.txt.par2 should be back to the expected value
diff -Nur "${tmp_par2_data_dir}/.par2" "test_fileset_par2_expected"
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:check_pruning_par2_file_for_deleted_data_file"
assert "par2 file for 2.txt doesn't exist" [[ -f "${tmp_par2_data_dir}/.par2/2.txt.par2" ]]
rm "${tmp_par2_data_dir}/2.txt"
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
assert "par2 file should NOT exist" ! [[ -f "${tmp_par2_data_dir}/.par2/2.txt.par2" ]]
echo "PASS: ${TC_NAME}"

TC_NAME="${0}:check_pruning_empty_par2_directory"
mkdir "${tmp_par2_data_dir}/level2_dir"
mv "${tmp_par2_data_dir}"/*txt "${tmp_par2_data_dir}/level2_dir"
run_fileset_par2 "${tmp_par2_data_dir}" --use_hidden_dir
assert "Emtpy par2 dir should NOT exist" ! [[ -d "${tmp_par2_data_dir}/.par2" ]]
echo "PASS: ${TC_NAME}"

# TODO: test stop_rc
