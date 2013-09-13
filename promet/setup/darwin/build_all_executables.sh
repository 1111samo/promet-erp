#!/bin/bash
cd darwin
echo "compiling for $1..."
echo "compiling messagemanager..."
lazbuild -q -B ../../source/messagemanager/messagemanager.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/messagemanager
echo "compiling promet..."
lazbuild -q -B ../../source/promet.erp/prometerp.lpi > scompile-$2.log
strip ../../output/$2-darwin/prometerp
echo "compiling pstarter..."
lazbuild -q ../../source/tools/pstarter.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/pstarter
echo "compiling sync_db..."
echo "compiling sync_db..." >> scompile-$2.log
lazbuild -q ../../source/sync/sync_db.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/sync_db
echo "compiling pop3receiver..."
echo "compiling pop3receiver..." >> scompile-$2.log
lazbuild -q ../../source/messageimport/pop3receiver.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/pop3receiver
echo "compiling rssreceiver..."
echo "compiling rssreceiver..." >> scompile-$2.log
lazbuild -q ../../source/messageimport/rssreceiver.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/rssreceiver
echo "compiling smtpsender..."
echo "compiling smtpsender..." >> scompile-$2.log
lazbuild -q ../../source/messageimport/smtpsender.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/smtpsender
echo "compiling statistics..."
lazbuild -q ../../source/statistics/statistics.lpi  >> scompile-$2.log
echo "compiling cdmenue..."
lazbuild -q ../../source/tools/cdmenue.lpi  >> scompile-$2.log
echo "compiling wizardmandant..."
lazbuild -q ../../source/tools/wizardmandant.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/wizardmandant
echo "compiling cmdwizardmandant..."
lazbuild -q ../../source/tools/cmdwizardmandant.lpi  >> scompile-$2.log
echo "compiling checkin/out..."
lazbuild -q ../../source/tools/checkin.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/checkin
lazbuild -q ../../source/tools/checkout.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/checkout
lazbuild -q ../../source/tools/tableedit.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/tools/tableedit
echo "compiling archivestore..."
lazbuild -q ../../source/archivestore/archivestore.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/archivestore
echo "compiling clientmanagement..."
lazbuild -q ../../source/clientmanagement/clientmanagement.lpi  >> strip ../../output/$2-darwin/clientmanagement
scompile-$2.log
echo "compiling helpviewer..."
lazbuild -q ../../source/tools/helpviewer.lpi  >> scompile-$2.log
strip ../../output/$2-darwin/helpviewer

