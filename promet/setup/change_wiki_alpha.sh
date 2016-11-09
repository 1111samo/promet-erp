#!/bin/bash
basedir=$(pwd)
cd promet/setup
Version=$(sed 's/\r//g' ../source/base/version.inc).$(sed 's/\r//g' ../source/base/revision.inc)
Version=$(echo $Version | sed 's/\n//g');
Arch=`dpkg --print-architecture`
Archfpc=$(fpc -h | grep 'Compiler version' | sed 's/.*for \([^ ]\+\)$/\1/')
Date=`date`
echo $STORA_CONN > ~/.prometerp/Stora.perml

lazbuild ../source/tools/changewikipage.lpi
echo Promet-ERP/dowloadplattforms/linux-$Archfpc
../output/$Archfpc-linux/changewikipage --mandant=Stora Promet-ERP/dowloadplattforms/alpha ../output/act_alphadownload.txt
../output/$Archfpc-linux/changewikipage --mandant=Stora Promet-ERP/changes ../source/base/changes.txt
../output/$Archfpc-linux/sync_db --mandant=Stora --db=Help
../output/$Archfpc-linux/sync_db --mandant=Stora --db=Server1
cd $basedir