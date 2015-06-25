#!/bin/bash
mkdir $2
mkdir $2/tools
cp ../../output/$1-linux/cmdwizardmandant $2
cp ../../output/$1-linux/checkin $2/tools
cp ../../output/$1-linux/checkout $2/tools
cp ../../output/$1-linux/tableedit $2
cp ../../output/$1-linux/clientmanagement $2
cp ../../output/$1-linux/archivestore $2
cp ../../output/$1-linux/pscript $2/tools
cp ../../output/$1-linux/tools/import_* $2/tools/
rm $2/tools/import_*.dbg
Version=$(sed 's/\r//g' ../../source/base/version.inc).$(sed 's/\r//g' ../../source/base/revision.inc)
Version=$(echo $Version | sed 's/\n//g');
cp $2/cmdwizardmandant ../executables/$Version/$1
cp $2/tools/checkin ../executables/$Version/$1
cp $2/tools/checkout ../executables/$Version/$1
cp $2/tableedit ../executables/$Version/$1
cp $2/archivestore ../executables/$Version/$1
cp $2/tools/pscript ../executables/$Version/$1
if [ ! -f $2/wizardmandant ];
then
    exit
fi
cp $2/clientmanagement ../executables/$Version/$1
if [ ! -f $2/clientmanagement ];
then
    exit
fi

