#!/bin/bash

echo "this script uploads a new postgres build to the app target"
echo "CAUTION:  this script might destroy your database!!!"

echo "enter name of target app:"
read targetapp

echo "enter full path of postgres archive file to upload:"
read knownpath

rhc scp $targetapp upload $knownpath app-root/data

echo "upgrading the crunchy pg database version..."

rhc ssh $targetapp --command pg/bin/upgrade.sh

echo "the upgrade is completed, log into your app to verify!"

