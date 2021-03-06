#!/bin/bash 

$OPENSHIFT_PGCLIENT_DIR/bin/create-tunnels-on-pgservers.sh

sleep 3

echo "replacing standby data with the master backup...."
mv $OPENSHIFT_DATA_DIR/.pg/data  $OPENSHIFT_DATA_DIR/.pg/data.orig
mkdir $OPENSHIFT_DATA_DIR/.pg/data 

chmod 700 $OPENSHIFT_DATA_DIR/.pg/data

pg_basebackup -R  \
--pgdata=$OPENSHIFT_DATA_DIR/.pg/data \
--host=$OPENSHIFT_PG_HOST --port=$PGCLIENT_STANDBY_PORT -U $PGCLIENT_MASTER_USER

echo "reconfiguring postgres conf files...."

sleep 4

$OPENSHIFT_PGCLIENT_DIR/bin/configure.sh
