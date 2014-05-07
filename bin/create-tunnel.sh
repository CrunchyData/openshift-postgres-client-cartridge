#!/bin/bash 

#
# for pgpool....
# create a tunnel to both the master and the standby server
#

#internalIP=`env | grep OPENSHIFT | grep IP | cut -d"=" -f2`
#echo $internalIP

echo dns list $JEFF_PG_STANDBY_DNS_LIST
dnsarray=($JEFF_PG_STANDBY_DNS_LIST)
echo user list $JEFF_PG_STANDBY_USER_LIST
userarray=($JEFF_PG_STANDBY_USER_LIST)
echo port list $JEFF_PG_STANDBY_PORT_LIST
portarray=($JEFF_PG_STANDBY_PORT_LIST)
#
# create tunnel to each standby postgres server
#

idx=0

for standby in ${dnsarray[*]};
do
	echo creating tunnel to ${dnsarray[idx]}
	nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:${portarray[idx]}:${dnsarray[idx]}:$PGCLIENT_REMOTE_PG_PORT \
${userarray[idx]}@${dnsarray[idx]} &> /dev/null &
	let "idx=$idx+1"
done

#
# create a tunnel to the master postgres server
#
nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:$PGCLIENT_MASTER_PORT:$PGCLIENT_MASTER_HOST:$PGCLIENT_REMOTE_PG_PORT \
$PG_MASTER_USER@$PG_MASTER_DNS &> /dev/null &

