#!/usr/bin/env bash
# Library function for remote backup
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

# listing snapshots to delete
list-snapshots-to-del() {
    EXIST_SS=$1
    SS_TO_KEEP=$2
    # remove the last digits before ".zpaq"
    SS_NAMES=`echo "$EXIST_SS" | sed -e 's/-[[:digit:]][[:digit:]]*.zpaq/-/g' | sort | uniq`
    SS_COUNT=`echo "$SS_NAMES" | wc -l`
    SS_TO_DEL=$(( $SS_COUNT - $SS_TO_KEEP ))
    if [ $SS_TO_DEL -gt 0 ]; then
        echo "${SS_NAMES}" | head -$SS_TO_DEL | sed -e "s/$/*/g"
    fi
}

get_latest_snapshot_number() {
    STAGING=$1
    ls "$STAGING"/* | grep -v index | tail -1 | sed -e "s/.*-\([[:digit:]][[:digit:]]*\).zpaq/\1/g"
}
