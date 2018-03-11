#!/bin/sh

if [ -z "$1" ]
then
    echo "$0: directory parameter missing" >&2
    exit 1
fi

WHEREAMI=$(dirname $(realpath $0))

for f in find "$1" -name '*.docx'
do
    echo Processing file $f
    dir=`dirname "$f"`
    basename=`basename "$f"`
    basenamenoext=`basename "$f" .docx`
    parentdir=`dirname "$dir"`
    mv "$f" "$parentdir/process"
    $WHEREAMI/docx2jats.sh "$parentdir/process/$basename" >"$parentdir/../results/process/$basenamenoext.log" 2>&1 
    zip -r "$parentdir/../results/process/$basenamenoext.zip" "$parentdir/process/$basenamenoext"
    rm -Rf "$parentdir/process/$basename" "$parentdir/process/$basenamenoext"
done

