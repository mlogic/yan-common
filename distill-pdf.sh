#!/bin/bash
# Distill a PDF and generate a (somehow) PDF/A compliant document. The
# result is not fully compliant but should be safe for most readers.
#
# Ref: http://unix.stackexchange.com/questions/79516/converting-pdf-to-pdf-a
#
# Copyright (c) 2016, Yan Li <yanli@ascar.io>,
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
set -e -u

if [ $# -eq 0 ]; then
    cat<<EOF
Usage: $0 -n src [dst]
-n    Do not use pdfdef.ps. This can be used to distill small figures
      that will be inserted into LaTeX documents to generate a
      compliant document.
If dst is missing, a file named src_distilled.pdf will be generated.
EOF
    exit 2
fi
USE_PDFDEF=1
if [ "$1" = "-n" ]; then
    USE_PDFDEF=0
    shift
fi

TMP=`mktemp`

echo "Distilling $1..."

# ghostscript cannot handle PDF->PDF correctly. The foolproof way is
# to do pdf2ps first. The problem is this damages some information
# such as bookmarks.
pdf2ps "$1" "$TMP"

if [ $# -ge 2 ]; then
    DST=$2
else
    DST=${1%.*}_distilled.pdf
fi

if [ $USE_PDFDEF -eq 0 ]; then
    INPUT_FILES=("$TMP")
elif [ ! -f pdfdef.ps ]; then
    cat<<EOF
WARNING: pdfdef.ps missing. Follow
http://svn.ghostscript.com/ghostscript/trunk/gs/doc/Ps2pdf.htm#PDFA to prepare it.
EOF
    INPUT_FILES=("$TMP")
else
    INPUT_FILES=(pdfdef.ps "$TMP")
fi

gs -sDEVICE=pdfwrite -q -dNOPAUSE -dBATCH -dNOSAFER     \
    -dPDFA -dUseCIEColor -sProcessColorModel=DeviceCMYK \
    -dEmbedAllFonts=true -dPDFACompatibilityPolicy=2    \
    -dDetectDuplicateImages -dFastWebView=true \
    -sOutputFile="$DST" ${INPUT_FILES[@]}
