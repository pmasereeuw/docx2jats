#!/bin/bash

# This is where docx files are copied for future use. Make sure it is writable for the webserver (www-data):
DOCX_VAULT=/home/pieter/ibo

if [ -z "$1" ]
then
    echo "$0: directory parameter missing" >&2
    exit 1
fi

WHEREAMI=$(dirname $(realpath $0))

for f in `find "$1" -name '*.docx'`
do
    echo Processing file $f
    cp "$f" "$DOCX_VAULT"
    dir=`dirname "$f"`
    basename=`basename "$f"`
    basenamenoext=`basename "$f" .docx`
    parentdir=`dirname "$dir"`
    mv "$f" "$parentdir/process"
    logfile=$parentdir/results/$basenamenoext.log
    echo "Start of docx2jats conversion of $basename on `date`" >$logfile 
    $WHEREAMI/docx2jats.sh "$parentdir/process/$basename" >>"$logfile" 2>&1
    resultdir=$parentdir/process/$basenamenoext
    if [ -d "$resultdir" ]
    then
        SAVEDIR=`pwd`
        cd "$resultdir"
        zip -r "$resultdir.zip" *
        cd "$SAVEDIR"
    else
        echo "Directory $resultdir is missing, giving up" >>"$logfile"
    fi
    echo "End of docx2jats conversion of $basename on `date`" >>$logfile 
    rm -Rf "$parentdir/process/$basename" "$parentdir/process/$basenamenoext"
done

