#!/bin/bash
DIR=$(dirname "$1")
FILE=$(basename "$1")

AUTOUPLOAD_PORT=232
AUTOUPLOAD_USER=autoupload
AUTOUPLOAD_HOST=downloads.free-erp.de

echo "uploading $1..."
scp -P $AUTOUPLOAD_PORT $basedir/promet/setup/output/$1 $AUTOUPLOAD_USER@$AUTOUPLOAD_HOST:promet_upload_target
ssh $AUTOUPLOAD_USER@$AUTOUPLOAD_HOST -p $AUTOUPLOAD_PORT "cd promet_upload_target;ln -s -f $FILE $2"
#scp $2 christian_u@frs.sourceforge.net:/home/frs/project/Promet-ERP/
