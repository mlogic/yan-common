#!/usr/bin/env bash
# Test case for test-old-snapshot-to-del
# 
# Copyright (c) 2016-2018, Yan Li <yanli@tuneup.ai>,
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

cd `dirname $0`
. ../_support_funcs.sh

EXIST_SNAPSHOTS=`ls mock-staging/*`
SNAPSHOTS_TO_DEL=`list-snapshots-to-del "$EXIST_SNAPSHOTS" 2`
EXP_SNAPSHOTS_TO_DEL="mock-staging/snapshot-2016-03-24-*
mock-staging/snapshot-2016-04-23-*"

[ "$EXP_SNAPSHOTS_TO_DEL" = "$SNAPSHOTS_TO_DEL" ]

[ `get_latest_snapshot_number mock-staging` -eq 4 ]

echo "PASS: $0"
