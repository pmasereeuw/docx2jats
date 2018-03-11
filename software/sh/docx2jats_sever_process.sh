#!/bin/sh

if [ -z "$1" ]
then
    echo "$0: directory parameter missing" >&2
    exit 1
fi

WHEREAMI=$(dirname $(realpath $0))

for f in "$1"/*.docx
do
    echo Processing file $f
    $WHEREAMI/docx2jats.sh "$f"
done

