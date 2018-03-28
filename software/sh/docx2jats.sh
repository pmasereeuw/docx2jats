#!/bin/bash

USAGE="Usage: $0 [-keeptmp] docx-file [lang-code]"

WHEREAMI=$(dirname $(realpath $0))
if [ `whoami` = pieter ]
then
   source "$WHEREAMI/sourceme"
else
   source "$WHEREAMI/sourceme-`hostname`"
fi

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

if [ -d "$outputfolder" ]
then
   rm -Rf "$outputfolder"
fi

SAVEDIR=`pwd`
cd "$SOFTWAREFOLDER/..";
BRANCH=`git branch | grep \* | cut -d ' ' -f2-`
VERSION=`git describe --tags --always`
cd "$SAVEDIR"

echo Git repo version: $VERSION, branch $BRANCH

"$SHFOLDER/xproc.sh" "$XPLFOLDER/docx2jats.xpl" \
  "debug=$DEBUG" \
  "relsfile=file://$workfolder/_rels/.rels" \
  "outputfile=file://$outputfolder/$basedocxfile.xml" \
  "inputmediadirectory=file://$workfolder/word/media" \
  "outputmediadirectory=file://$outputfolder" \
  "language-code=$language_code" \
  "prefix-to-rng-schema=$PREFIX_TO_RNG_SCHEMA" \
  "prefix-to-sch-schema=$PREFIX_TO_SCH_SCHEMA" \
  "git-branch=$BRANCH" \
  "git-version=$VERSION"

if [ $KEEPTMP = yes ]
then
    echo "Tijdelijke bestanden staan in $workfolder"
else
    rm -Rf "$workfolder"
fi
