#!/usr/bin/env bash
# VirtualBox: Remove old auto snapshots
#
# Copyright (c) 2015-2021, Yan Li <yanli@tuneup.ai>,
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

if [ $# -lt 2 ]; then
cat<<EOF
Check all snapshots that match pattern, keep the last n and remove all others
Usage: $0 [-d] vm pattern [n]
-d:      dry run
vm:      name of the VirtualBox VM
pattern: the pattern of the snapshots
n:       number of snapshots to keep (default to 4)

Sample:
$0 my-vm auto
EOF
fi
DRYRUN_CMD=
if [ "$1" = "-d" ]; then
    echo "Dry run. Listing commands to run:"
    DRYRUN_CMD=echo
    shift
fi

VM=$1
PATTERN=$2
N=${3:-4}

AUTO_SNAPSHOTS=`vboxmanage snapshot $VM list | awk '{print $2}' | grep -E ${PATTERN} | sort`
TOTAL_SS=`echo "$AUTO_SNAPSHOTS" | wc -l`
SS_TO_DEL=$(( $TOTAL_SS - $N ))
if [ $SS_TO_DEL -le 0 ]; then exit; fi

# Deleting snapshots in reverse order is faster
echo "$AUTO_SNAPSHOTS" | head -$SS_TO_DEL | tac | xargs -n 1 $DRYRUN_CMD vboxmanage snapshot $VM delete

