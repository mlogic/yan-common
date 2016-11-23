#!/bin/bash
# Distill a PDF using Ghostscript. You have the option to generate a
# PDF/A-2b (default) or PDF/X compliant document. Due to bugs of
# Ghostscript, sometimes the result might not be fully compliant but
# should be safe for most readers.
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
Usage: $0 [options] src [dst]

Using the latest Ghostscript is highly recommended because old
versions -- especially before 2.11 -- have many bugs. Ghostscript
website provides easy-to-use static binaries for Linux.

If dst is missing, a file named src_distilled.pdf will be generated.

-a    PDF/A-2b (default).
-x    PDF/X.
-p    Do a pdf2ps pass first. WARNING: Use this only if other methods failed to
      generate compliant files for you. This generates the most compliant
      document but if any page of your document has transparent objects
      the whole page will be rasterized. Also PDF bookmarks and links
      will be lost.
-n    Do not use pdfdef.ps. This can be used to distill small figures
      that will be inserted into LaTeX documents to generate a
      compliant document.
EOF
    exit 2
fi

PDFA=0
PDFX=0
PSPASS=0
USE_PDFDEF=1
while getopts "axpn" var; do
    case $var in
        a)
            PDFA=1
            ;;
        x)
            PDFX=1
            ;;
        p)
            PSPASS=1
            ;;
        n)
            USE_PDFDEF=0
            ;;
	?)
	    exit 1
            ;;
    esac
done
shift $(( $OPTIND - 1 ))

if [ $PDFA -eq 1 -a $PDFX -eq 1 ]; then
    echo "Cannot specify both PDF/A and PDF/X. Exiting..."
    exit 2
elif [ $PDFX -eq 1 ]; then
    PDFMODE=X
else
    PDFMODE=A
fi

if [ $# -ge 2 ]; then
    DST=$2
else
    DST=${1%.*}_distilled.pdf
fi

echo "Distilling $1..."

if [ $PSPASS -eq 1 ]; then
    TMP=`mktemp`
    pdf2ps "$1" "$TMP"
    SRC=$TMP
else
    SRC=$1
fi

if [ $USE_PDFDEF -eq 0 ]; then
    INPUT_FILES=("$SRC")
elif [ ! -f pdfdef.ps ]; then
    cat<<EOF
WARNING: pdfdef.ps missing. Follow
http://svn.ghostscript.com/ghostscript/trunk/gs/doc/Ps2pdf.htm#PDFA to prepare it.
EOF
    INPUT_FILES=("$SRC")
else
    INPUT_FILES=(pdfdef.ps "$SRC")
fi

# Ghostscript 9.11+ recommends against using -dUseCIEColor
ARGS=(-sDEVICE=pdfwrite -q -dNOPAUSE -dBATCH -dNOSAFER -sProcessColorModel=DeviceCMYK
      -dEmbedAllFonts=true -dDetectDuplicateImages -dFastWebView=true -dPDFACompatibilityPolicy=1)

if [ $PDFMODE = A ]; then
    ARGS+=(-dPDFA=2)
elif [ $PDFMODE = X ]; then
    ARGS+=(-dPDFX)
fi

gs "${ARGS[@]}" -sOutputFile="$DST" "${INPUT_FILES[@]}"
