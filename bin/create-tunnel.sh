#!/bin/bash 

#
# for pgpool....
# create a tunnel to both the master and the standby server
#

#internalIP=`env | grep OPENSHIFT | grep IP | cut -d"=" -f2`
#echo $internalIP

nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:$PGCLIENT_STANDBY_PORT:$PG_STANDBY_IP:$PGCLIENT_REMOTE_PG_PORT \
$PG_STANDBY_USER@$PG_STANDBY_DNS &> /dev/null &

nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:$PGCLIENT_MASTER_PORT:$PG_MASTER_IP:$PGCLIENT_REMOTE_PG_PORT \
$PG_MASTER_USER@$PG_MASTER_DNS &> /dev/null &

