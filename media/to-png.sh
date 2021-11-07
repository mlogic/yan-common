#!/usr/bin/env bash
# Losslessly convert an image to png using OptiPNG
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

if [ $# -lt 1 ]; then
    cat<<END
Convert files to PNG format losslessly
Usage: $0 [-d] files...
Option:
 -d    remove source file
END
    exit 2
fi

DEL_SRC=0
if [ "$1" = "-d" ]; then
    DEL_SRC=1
    shift 1
fi

for file in "$@"; do
    basename="${file%.*}"
    ext="${file##*.}"
    if [ "${ext,,}" != "png" ]; then
        # OptiPNG is finicky about input formats other than PNG. We
        # just convert all others to png for simplicity.

        # Bail out if the tmp file name would 
        # mimg-compress-1.png might still exist.
        if [ -e "${basename}-tmp*.png" ];

        convert "$file" /tmp/mimg-compress.png
        # Certain files such as TIF could have more than one image, and convert
        # will output more than one file. We pick the larger one to use.
        tmpfile=`ls -S /tmp/mimg-compress*.png | head -1`
    else
        tmpfile="$file"
    fi
    optipng -preserve "$tmpfile" -o "${basename}.webp"
    if [ ${DEL_SRC} -eq 1 ]; then
        rm "${file}"
    fi
done
