#/bin/bash
echo "Building help..."
basedir=$(pwd)
cd promet/help
rm -r $BUILD_DIR
mkdir $BUILD_DIR
cp help.db $BUILD_DIR
sqlite3 $BUILD_DIR/help.db "delete from DOCUMENTS where TYPE<>'W';delete from HISTORY;delete from REPORTS;delete from ACCHISTORY;delete from TEMPLATES;delete from DOCPAGES;delete from DELETEDITEMS;delete from THUMBNAILS;delete from TASKS;delete from OPTIONS;delete from MESSAGEIDX;delete from MESSAGES;vacuum;"
cd $BUILD_DIR
target=help
targetfile=$target-$BUILD_VERSION.zip
targetcur=$target-current.zip
zip -rq $basedir/promet/setup/output/$BUILD_VERSION/$targetfile .
. ../../setup/build-tools/doupload.sh $targetfile $targetcur &
cd $basedir
