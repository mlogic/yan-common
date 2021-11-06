#!/usr/bin/env bash
# Change framerate of a video file without reencoding
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

if [[ $# -lt 3 ]]; then
  cat<< EOF
Change the framerate of a video file without reencoding. Audio will be dropped.

Usage: $0 frame_rate input_file output_file [extra options]

Extra options will be passed directly to ffmpeg before -i. For instance:
$0 30 input.mp4 output.mp4 -ss 00:13:21.281 -to 00:13:28.512
EOF
  exit 2
fi

declare -r TARGET_FRAMERATE=$1
declare -r INPUT=$2
declare -r OUTPUT=$3
shift 3

INPUT_CODEC="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "${INPUT}")"
readonly INPUT_CODEC
TMP_OUTPUT="$(mktemp --dry-run)"
readonly TMP_OUTPUT

# Extra the raw video stream first using the format identified above
ffmpeg "$@" -i "${INPUT}" -c:v copy -f "${INPUT_CODEC}" "${TMP_OUTPUT}"

# Re-save the raw video stream using the target frame rate
ffmpeg -r "${TARGET_FRAMERATE}" -i "${TMP_OUTPUT}" -c:v copy "${OUTPUT}"
