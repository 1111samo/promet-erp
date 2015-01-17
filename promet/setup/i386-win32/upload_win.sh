#!/bin/bash
Version=$(sed 's/\r//g' ../../source/base/version.inc).$(sed 's/\r//g' ../../source/base/revision.inc)
Version=$(echo $Version | sed 's/\n//g');
chmod 644 output/*
scp ../output/*_$(echo $Version)_$1*.exe autoupload@178.254.12.54:promet_upload_target
scp ../output/db_setup*.exe autoupload@178.254.12.54:promet_upload_target
