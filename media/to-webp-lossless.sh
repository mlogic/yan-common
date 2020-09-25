#!/usr/bin/env bash
# Losslessly convert an image to webp with the best compression for archive
#
# ImageMagick is used to convert input files that weren't supported by
# cwebp to PNG. You will also need exiftool for preserving the
# metadata.
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

if [ $# -lt 1 ]; then
    cat<<END
Convert files to webp format losslessly
Usage: $0 [-d] files...
Option:
 -d    remove source file

WARNING! If the input file contains more than one image, such as
GIF/TIF, only one image would be retained in the output file.
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
        # cwebp doesn't take most formats other than png (it could
        # read some tif but not all). We just convert all others to
        # png for simplicity.

        # Remove residual files from before. Some files like
        # mimg-compress-1.png might still exist.
        rm -f /tmp/mimg-compress*.png

        if [ "${ext,,}" = "tif" ]; then
            # Use GraphicsMagick for TIF because ImageMagick's TIF
            # handling is so broken.
            gm convert "$file" /tmp/mimg-compress.png
        else
            # GraphicsMagick doesn't support PSD. So we have to use
            # ImagicMagick for other formats.
            convert "$file" /tmp/mimg-compress.png
        fi
        # Certain files such as TIF could have more than one image,
        # and convert will output more than one file. We pick the
        # largest one to use.
        tmpfile=`ls -S /tmp/mimg-compress*.png | head -1`
    else
        tmpfile="$file"
    fi
    cwebp -lossless -m 6 -metadata all "$tmpfile" -o /tmp/mimg-tmp.webp
    # cwebp doesn't handle metadata well. For instance, it couldn't
    # extract metadata from TIF and lost many tags from PNG
    # (12/7/2018). We use exiftool and webpmux instead.  The existing
    # /tmp/metadata.xmp must be removed, otherwise exiftool modifies
    # existing file without removing it.
    XMP_FILE=/tmp/metadata.xmp
    rm -f "$XMP_FILE"
    exiftool -tagsFromFile "$file" "$XMP_FILE"
    webpmux -set xmp "$XMP_FILE" /tmp/mimg-tmp.webp -o "${basename}.webp"
    if [ ${DEL_SRC} -eq 1 ]; then
        rm "${file}"
    fi
done
