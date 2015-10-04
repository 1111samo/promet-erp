#!/bin/bash
basedir=$(pwd)
cd promet/source/sync
. ../../setup/build-tools/setup_enviroment.sh
echo "Building mail components..."
# Build components
$lazbuild smtpsender.lpi $BUILD_ARCH $BUILD_PARAMS > build.txt
if [ "$?" -ne "0" ]; then
  echo "build failed"
  $grep -w "Error:" build.txt
  exit 1
fi
$lazbuild pop3receiver.lpi $BUILD_ARCH $BUILD_PARAMS > build.txt
if [ "$?" -ne "0" ]; then
  echo "build failed"
  $grep -w "Error:" build.txt
  exit 1
fi
cd $basedir/promet/output/$TARGET_CPU-$TARGET_OS
zip $basedir/promet/setup/output/$BUILD_VERSION/mailreceiver_$TARGET_CPU-$TARGET_OS-$BUILD_VERSION.zip tools/pop3receiver$TARGET_EXTENSION tools/smtpsender$TARGET_EXTENSION
cd $basedir
