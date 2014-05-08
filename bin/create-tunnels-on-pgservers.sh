#!/bin/bash 

echo "create-tunnels called for " $PG_NODE_TYPE

if [ "$PG_NODE_TYPE" == "master" ]; then
	#nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
	#-i ~/.openshift_ssh/pg_rsa_key \
	#-N -L \
	#$OPENSHIFT_PG_HOST:$PG_TUNNEL_PORT:$PG_STANDBY_IP:$PG_PORT \
	#$PG_STANDBY_USER@$PG_STANDBY_DNS &> /dev/null &
	echo "specifically not creating tunnels on master"
elif [ "$PG_NODE_TYPE" == "standby" ]; then
	nohup ssh -o UserKnownHostsFile=~/.openshift_ssh/known_hosts \
	-i ~/.openshift_ssh/pg_rsa_key \
	-N -L \
	$OPENSHIFT_PG_HOST:$PGCLIENT_STANDBY_PORT:$PGCLIENT_MASTER_IP:$PG_PORT \
	$PGCLIENT_MASTER_USER@$PGCLIENT_MASTER_DNS &> /dev/null &
fi

