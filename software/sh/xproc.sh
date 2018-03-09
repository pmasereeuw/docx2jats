#!/bin/sh

USAGE="$0 xproc-script [ name=value ]..."

if [ -z "$1" ]
then
    echo $USAGE >&2
    exit 1
fi

XPLFILE=$1
shift

"$JAVACMD" \
     -Xmx$JAVA_XMX \
     -cp "$CALABASH_JAR:$CALABASHFOLDER/lib/saxon9pe.jar" \
     com.xmlcalabash.drivers.Main \
     --saxon-processor pe \
     "$@" \
    "$XPLFILE"