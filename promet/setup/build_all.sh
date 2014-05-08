#!/bin/bash
Version=$(sed 's/\r//g' ../source/base/version.inc).$(sed 's/\r//g' ../source/base/revision.inc)
Version=$(echo $Version | sed 's/\n//g');
sudo -S rm output/*
mkdir executables/$Version
mkdir executables/$Version/x86_64
mkdir executables/$Version/i386
lazbuild ../source/testcases/consoletest.lpi
../output/x86_64-linux/consoletest --mandant=Test
if [ "$?" -ne "0" ]; then
  echo "Testcases failed exitting"
  exit 1
fi
sudo -S ./clean_all.sh
#sh build_win_wine_i386.sh &
cd i386-linux
./build_all.sh
cd ..
ssh chris@minimac 'sh promet/promet/setup/build_all.mac' &
#cd $FULL_NAME/zip-files
#./build_stick.sh
#cd ..
