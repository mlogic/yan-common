#!/usr/bin/env bash
# Compare local and remote git branches
#
# Based on a script from https://stackoverflow.com/a/3278427
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
set -euo pipefail

if [ x${1:-} = x-h ]; then
    cat<<EOF
Usage: $0 [upstream-branch]

Compare local and remote git branches.

This script doesn't do "git fetch" for you. You need to do it before
calling this script.

You can optionally pass the name of the upstream branch. If omitted,
the current branch and its remote will be compared.

Return code:
  0: Local == remote
  1: Error
  2: Help message shown
  10: Need to pull
  11: Need to push
  12: Diverged
EOF
    exit 2
fi

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base HEAD "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "Up-to-date"
    exit 0
elif [ $LOCAL = $BASE ]; then
    echo "Need to pull"
    exit 10
elif [ $REMOTE = $BASE ]; then
    echo "Need to push"
    exit 11
else
    echo "Diverged"
    exit 12
fi
