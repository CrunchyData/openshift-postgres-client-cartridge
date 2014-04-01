#!/bin/bash 

#
# create a tunnel to both the master and the standby server
#

#internalIP=`env | grep OPENSHIFT | grep IP | cut -d"=" -f2`
#echo $internalIP

nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:15001:$PG_STANDBY_IP:5432 \
$PG_STANDBY_USER@$PG_STANDBY_DNS &> /dev/null &

nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:15000:$PG_MASTER_IP:5432 \
$PG_MASTER_USER@$PG_MASTER_DNS &> /dev/null &

