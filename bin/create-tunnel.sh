#!/bin/bash 

#
# create a tunnel to both the master and the standby server
#

nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/app-root/data/pg_rsa_key \
-N -L \
$OPENSHIFT_JBOSSEWS_IP:15001:$PG_STANDBY_IP:5432 \
$PG_STANDBY_USER@$PG_STANDBY_DNS &> /dev/null &

nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/app-root/data/pg_rsa_key \
-N -L \
$OPENSHIFT_JBOSSEWS_IP:15000:$PG_MASTER_IP:5432 \
$PG_MASTER_USER@$PG_MASTER_DNS &> /dev/null &

