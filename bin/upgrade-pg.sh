#!/bin/bash

echo "this script uploads a new postgres build to the app target"
echo "CAUTION:  this script might destroy your database!!!"

echo "enter name of target app:"
read targetapp

echo "enter full path of postgres archive file to upload:"
read knownpath
thebase=`basename $knownpath`
echo "base=" $thebase

rhc scp $targetapp upload $knownpath app-root/data

echo "upgrading the crunchy pg database version..."

echo "shutting down the postgres database..."

rhc cartridge-stop crunchydatasolutions-pg-1.0 --app $targetapp

rhc ssh -a $targetapp --command 'pg/bin/perform-upgrade.sh app-root/data/$thebase'

echo "starting the postgres database...."

rhc cartridge-start crunchydatasolutions-pg-1.0 --app $targetapp

echo "the upgrade is completed, log into your app to verify!"

