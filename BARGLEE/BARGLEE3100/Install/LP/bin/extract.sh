#!/bin/bash

JAVA=jre/bin/java
JRE_TARBALL=../bin/jre.tar.bz2
JARFILE=../bin/barpunch.jar

if [ $# -lt 1 ]
then
	echo "Usage: $0 image"
	exit 1
fi

punch=$1

if [ ! -e $JAVA ]
then
    if [ -e $JRE_TARBALL ]
    then
        tar xjf $JRE_TARBALL
    else
        echo "Could not find the JRE ($JRE_TARBALL)"
        exit 1
    fi
fi

cp $JARFILE .
JARFILE=$(basename $JARFILE)

tmp=${punch}.extended
cat $punch <(dd if=/dev/zero bs=$((0x20000)) count=1 2>/dev/null) > $tmp
punch=$tmp

$JAVA -classpath $JARFILE example.ExtractSegment $punch all

$JAVA -classpath $JARFILE example.ExtractModule $punch all

comp_punch_ua=${tmp}*-0x2658-0x8086-c.bin
decomp_punch_ua=$(echo $comp_punch_ua | sed 's/-c.bin/-d.bin/')

$JAVA -classpath $JARFILE example.DeCompress d $comp_punch_ua $decomp_punch_ua

rm $punch #temp file

exit 0
