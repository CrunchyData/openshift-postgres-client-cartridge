#!/bin/bash 

#
# for pgpool....
# create a tunnel to both the master and the standby server
#

#internalIP=`env | grep OPENSHIFT | grep IP | cut -d"=" -f2`
#echo $internalIP

echo dns list $PGCLIENT_STANDBY_DNS_LIST
dnsarray=($PGCLIENT_STANDBY_DNS_LIST)
echo ip list $PGCLIENT_STANDBY_IP_LIST
iparray=($PGCLIENT_STANDBY_IP_LIST)
echo user list $PGCLIENT_STANDBY_USER_LIST
userarray=($PGCLIENT_STANDBY_USER_LIST)
echo port list $PGCLIENT_STANDBY_PORT_LIST
portarray=($PGCLIENT_STANDBY_PORT_LIST)
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
$OPENSHIFT_PGCLIENT_HOST:${portarray[idx]}:${iparray[idx]}:$PGCLIENT_REMOTE_PG_PORT \
${userarray[idx]}@${dnsarray[idx]} &> /dev/null &
	let "idx=$idx+1"
done

#
# create a tunnel to the master postgres server
#
nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
-i ~/.openshift_ssh/pg_rsa_key \
-N -L \
$OPENSHIFT_PGCLIENT_HOST:$PGCLIENT_MASTER_PORT:$PGCLIENT_MASTER_IP:$PGCLIENT_REMOTE_PG_PORT \
$PGCLIENT_MASTER_USER@$PGCLIENT_MASTER_DNS &> /dev/null &

