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

if [ $# -ne 2 ]; then
    cat<<EOF
Usage: $0 src dst
EOF
    exit 2
fi
TMP=`mktemp`

# ghostscript cannot handle PDF->PDF correctly. The foolproof way is
# to do pdf2ps first. The problem is this damages some information
# such as bookmarks.
pdf2ps "$1" "$TMP"

if [ ! -f pdfdef.ps ]; then
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
    -sOutputFile="$2" ${INPUT_FILES[@]}
