#!/bin/bash

echo "this script uploads security credentials to the app target"
echo "this provides connectivity to the postgres cluster from the target app"

echo "enter name of target app:"
read targetapp

echo "enter full path of pg_known_hosts file:"
read knownpath

echo "enter full path of pg_rsa_key:"
read keypath

rhc scp $targetapp upload $knownpath .openshift_ssh/known_hosts

rhc scp $targetapp upload $keypath .openshift_ssh/pg_rsa_key


