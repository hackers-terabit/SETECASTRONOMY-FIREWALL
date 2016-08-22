#!/bin/bash
JAVA=jre/bin/java
JRE_TARBALL=bin/jre.tar.bz2
JARFILE=bin/barpunch.jar

if [ $# -lt 6 ] || [ $6 -ne 300 -a $6 -ne 500 ]
then
	echo "Usage: $0 cleanimage core pbd ua output platform"
	echo "       (where platform must be either 300 or 500)"
	exit 1
fi

originalPunch=$1.extended
coreSegment=$2
pbdSegment=$3
userArea=$4
outputRom=$5
platformType=$6

if [ $platformType -eq 300 ]
then
    #wrong platform
    exit 1
else
    cat $1 <(dd if=/dev/zero bs=$((0x20000)) count=1 2>/dev/null) > $originalPunch
fi

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


echo -n .
if [ $platformType -eq 300 ]
then
bin/optromBuilder $userArea bin/toyUsbOptionRomHeader300.bin ${userArea}_OptRom.bin
else
bin/optromBuilder $userArea bin/toyUsbOptionRomHeader500.bin ${userArea}_OptRom.bin
fi
if [ $? -ne 0 ]
then
  echo "Unable to run builder successfully, aborting install."
  exit 1
fi
if [ $platformType -eq 300 ]
then
$JAVA -classpath $JARFILE example.AddModule $originalPunch 0x20 0x24D2:0x8086 ${userArea}_OptRom.bin uncompressed compressed _ua.rom
else
$JAVA -classpath $JARFILE example.AddModule $originalPunch 0x20 0x2658:0x8086 ${userArea}_OptRom.bin uncompressed compressed _ua.rom
fi
if [ $? -ne 0 ]
then
  echo "Unable to invoke AddModule successfully, aborting install."
  exit 1
fi

echo -n .
$JAVA -classpath $JARFILE example.InsertSegmentAtDest _ua.rom $pbdSegment 0xBA00 _ua_pbd.rom
if [ $? -ne 0 ]
then
  echo "Unable to invoke InsertSegmentAtDest successfully, aborting install."
  exit 1
fi

echo -n .
$JAVA -classpath $JARFILE example.InsertSegmentAtDest _ua_pbd.rom $coreSegment 0xA040 _ua_pbd_core.rom
if [ $? -ne 0 ]
then
  echo "Unable to invoke InsertSegmentAtDest successfully, aborting install."
  exit 1
fi

echo -n .
$JAVA -classpath $JARFILE example.ModifySegmentA000 _ua_pbd_core.rom $outputRom
if [ $? -ne 0 ]
then
  echo "Unable to invoke ModifySegmentA000 successfully, aborting install."
  exit 1
fi

echo " :: New rom image $outputRom was successfully created."

rm -f ${userArea}_OptRom.bin
rm -f _ua.rom _ua_pbd.rom _ua_pbd_core.rom
rm -rf java

exit 0
