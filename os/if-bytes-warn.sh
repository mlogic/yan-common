#!/usr/bin/env bash
# Send a warning email if bytes sent from all NICs exceed a limit
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

if [ $# -lt 2 -o $# -gt 3 ]; then
    cat<<EOF
$0 limit email [cmd]

Send an email when a sent bytes of all NICs exceeds the limit, and
optionally run cmd.

Emails are sent (and cmd is run) no more than once per hour.

EOF
    exit 2
fi
LIMIT=$1
EMAIL=$2
LAST_SENT_TIME_FILE=/tmp/yan-if-bytes-warn.time

SENT_BYTES=`cat /proc/net/dev | tail -n +3 | awk '{ print $10 }' | paste -s -d+ - | bc`
if [ $SENT_BYTES -gt $1 ]; then
    CURRENT_HOUR=`date +%Y-%m-%d_%H`

    if [ -f "$LAST_SENT_TIME_FILE" ]; then
        LAST_SENT_TIME=`cat "$LAST_SENT_TIME_FILE"`
        if [ x"$CURRENT_HOUR" == x"$LAST_SENT_TIME" ]; then
            # Do nothing
            exit 0
        fi
    fi
    echo "$CURRENT_HOUR" >"$LAST_SENT_TIME_FILE"

    cat<<EOF >/tmp/bytes-warn-email.txt
SENT BYTES EXCEED LIMIT ON `hostname`:
Limit: $LIMIT
Sent bytes: $SENT_BYTES
EOF
    if [ $# -eq 3 ]; then
        set +e
        $3 &>/tmp/bytes-warn-cmd.out
        set -e
        cat<<EOF >>/tmp/bytes-warn-email.txt

Executed command: $3
Command output:
EOF
        cat /tmp/bytes-warn-cmd.out >>/tmp/bytes-warn-email.txt
    fi
    mail -s "SENT BYTES EXCEED LIMIT ON `hostname`" "$EMAIL" </tmp/bytes-warn-email.txt
else
    rm -f "$LAST_SENT_TIME_FILE"
fi
