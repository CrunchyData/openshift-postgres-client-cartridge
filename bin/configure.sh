#!/bin/bash 

source $OPENSHIFT_CARTRIDGE_SDK_BASH

if [ "$PG_NODE_TYPE" == "master" ]; then
        client_result "configuring master postgres server "
        erb  $OPENSHIFT_PGCLIENT_DIR/conf/master/pg_hba.conf.erb > $OPENSHIFT_DATA_DIR/.pg/data/pg_hba.conf
        erb  $OPENSHIFT_PGCLIENT_DIR/conf/master/postgresql.conf.erb > $OPENSHIFT_DATA_DIR/.pg/data/postgresql.conf
else
if [ "$PG_NODE_TYPE" == "standby" ]; then
        client_result "configuring standby postgres server this time"
        erb  $OPENSHIFT_PGCLIENT_DIR/conf/standby/pg_hba.conf.erb > $OPENSHIFT_DATA_DIR/.pg/data/pg_hba.conf
        erb  $OPENSHIFT_PGCLIENT_DIR/conf/standby/postgresql.conf.erb > $OPENSHIFT_DATA_DIR/.pg/data/postgresql.conf
        erb  $OPENSHIFT_PGCLIENT_DIR/conf/standby/recovery.conf.erb > $OPENSHIFT_DATA_DIR/.pg/data/recovery.conf
else
    client_result "problem found....server is not marked as master or standby"
fi
fi

