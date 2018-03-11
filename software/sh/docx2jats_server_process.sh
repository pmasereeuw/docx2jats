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
    echo "End of docx2jats conversion of $basename on `date`" >>$logfile 
    zip -r "$parentdir/results/$basenamenoext.zip" "$parentdir/process/$basenamenoext"
    rm -Rf "$parentdir/process/$basename" "$parentdir/process/$basenamenoext"
done

