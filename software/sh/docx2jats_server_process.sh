#!/bin/bash

if [ -z "$1" ]
then
    echo "$0: directory parameter missing" >&2
    exit 1
fi

WHEREAMI=$(dirname $(realpath $0))

for f in `find "$1" -name '*.docx'`
do
    echo Processing file $f
    dir=`dirname "$f"`
    basename=`basename "$f"`
    basenamenoext=`basename "$f" .docx`
    parentdir=`dirname "$dir"`
    mv "$f" "$parentdir/process"
    logfile=$parentdir/results/$basenamenoext.log
    echo "Start of docx2jats conversion of $basename on `date`" >$logfile 
    $WHEREAMI/docx2jats.sh "$parentdir/process/$basename" >>"$logfile" 2>&1
    SAVEDIR=`pwd`
    cd "$parentdir/process/$basenamenoext"
    zip -r "$parentdir/results/$basenamenoext.zip" *
    cd "$SAVEDIR"
    echo "End of docx2jats conversion of $basename on `date`" >>$logfile 
    rm -Rf "$parentdir/process/$basename" "$parentdir/process/$basenamenoext"
done

