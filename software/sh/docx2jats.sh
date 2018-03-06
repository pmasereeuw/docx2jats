#!/bin/bash

USAGE="Usage: $0 [-keeptmp] docx-file [lang-code]"

WHEREAMI=$(dirname $(realpath $0))
# sourceme should be a softlink to the real sourceme file
SOURCEMEDIR=$(dirname $(readlink -f "$WHEREAMI/sourceme"))
source "$WHEREAMI/sourceme" "$SOURCEMEDIR"

# Check if DEBUG is part of the envirnoment. Otherwise set it.
if [ -z "$DEBUG" ]
then
    DEBUG=false
fi

if [ "$1" = "-keeptmp" ]
then
    KEEPTMP=yes
    shift 1
else
    KEEPTMP=no
fi


if [ -z "$1" ]
then
    echo $USAGE >&2
    exit 1
fi

TMPFOLDER=/tmp
BINDIR=`dirname "$0"`

docxfile=$1
language_code=$2

basedocxfile=`basename "$docxfile" .docx`
fullpathdocxfile=`realpath "$docxfile"`
dirofdocxfile=`dirname "$fullpathdocxfile"`
outputfolder=$dirofdocxfile/$basedocxfile
if [ $KEEPTMP = yes ]
then
     workfolder=$TMPFOLDER/$basedocxfile
else
     workfolder=$TMPFOLDER/$basedocxfile.$$
fi

rm -Rf "$workfolder"
unzip -q -d "$workfolder" "$docxfile"

if [ ! -f "$workfolder"/_rels/.rels ]
then
    echo "Unzipped DOCX-file does not contain expected file $workfolder/_rels/.rels - exiting"
    exit 2
fi

#xslt $BINDIR/docx2jats.xslt "$workfolder"/_rels/.rels "$dirofdocxfile/$basedocxfile.xml" "language-code=$language_code"

"$SHFOLDER/xproc.sh" "$XPLFOLDER/docx2jats.xpl" \
  "debug=$DEBUG" \
  "relsfile=file://$workfolder/_rels/.rels" \
  "outputfile=file://$outputfolder/$basedocxfile.xml" \
  "inputmediadirectory=file://$workfolder/word/media" \
  "outputmediadirectory=file://$outputfolder" \
  "language-code=$language_code" \
  "prefix-to-rng-schema=$PREFIX_TO_RNG_SCHEMA" \
  "prefix-to-sch-schema=$PREFIX_TO_SCH_SCHEMA"

if [ $KEEPTMP = yes ]
then
    echo "Tijdelijke bestanden staan in $workfolder"
else
    rm -Rf "$workfolder"
fi
