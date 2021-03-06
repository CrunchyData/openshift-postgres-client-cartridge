#!/bin/bash

#
# script which creates a client application, then
# installs the crunchy pgclient cartridge on it
#

defaultdomain="example.com"
echo "enter your domain name ["$defaultdomain"]:"
read domainname

if [[ -z $domainname ]];
	then domainname=$defaultdomain;
fi

currentname=`rhc domain list | head -1 | cut -f 2 -d " "`
echo "enter your openshift domain name ["$currentname"]:"
read openshiftdomain
if [[ -z $openshiftdomain ]];
	then openshiftdomain=$currentname;
fi

defaultwebframework="jbossews-2.0"
echo "enter the web framework to use ["$defaultwebframework"]:"
read webframework
if [[ -z $webframework ]];
    then webframework=$defaultwebframework;
fi

defaultknownpath=`pwd`/pg_known_hosts
echo "enter full path of known_hosts file [" $defaultknownpath "]:"
read knownpath

if [[ -z $knownpath ]];
    then knownpath=$defaultknownpath;
fi

defaultkeypath=`pwd`/pg_rsa_key
echo "enter full path of pg_rsa_key [" $defaultkeypath "]:"
read keypath

if [[ -z $keypath ]];
    then keypath=$defaultkeypath;
fi

defaultappname="pgclientapp"
echo "enter the name of the client app to create ["$defaultappname"]:"
echo "caution:  this script deletes the app if it already exists!!"
read clientname
if [[ -z $clientname ]];
    then clientname=$defaultappname;
fi

echo "enter your master postgres app name:"
read pgmaster

#
# perform cleanup if this client already existed
#
rhc app-delete -a $clientname --confirm
/bin/rm -rf $clientname

rhc create-app -a $clientname -t $webframework
echo $clientname " created..."

#force a key to be added to your local known_hosts file
rhc ssh -a $clientname --command 'date'

echo "copying key to servers...."

rhc scp $clientname upload $knownpath .openshift_ssh/known_hosts

rhc scp $clientname upload $keypath .openshift_ssh/pg_rsa_key

#
# now we are ready to install the client cartridge
#


pgmasterip=`rhc ssh -a $pgmaster 'echo $OPENSHIFT_PG_HOST'` 2> /dev/null
pgmasteruser=`rhc ssh -a $pgmaster 'echo $USER'` 2> /dev/null
pgstandbyuserlist=`rhc ssh -a $pgmaster 'echo $PGCLIENT_STANDBY_USER_LIST'` 2> /dev/null
pgstandbydnslist=`rhc ssh -a $pgmaster 'echo $PGCLIENT_STANDBY_DNS_LIST'` 2> /dev/null
pgstandbyportlist=`rhc ssh -a $pgmaster 'echo $PGCLIENT_STANDBY_PORT_LIST'` 2> /dev/null
pgstandbyiplist=`rhc ssh -a $pgmaster 'echo $PGCLIENT_STANDBY_IP_LIST'` 2> /dev/null

masterdns=$pgmaster-$currentname.$domainname
echo $masterdns is dns for master

echo "installing crunchy pgclient cartridge onto " $clientname

rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $clientname  --env PGCLIENT_MASTER_DNS=$masterdns --env PGCLIENT_STANDBY_DNS_LIST="$pgstandbydnslist" --env PGCLIENT_STANDBY_PORT_LIST="$pgstandbyportlist" --env PGCLIENT_STANDBY_USER_LIST="$pgstandbyuserlist" --env PGCLIENT_MASTER_USER="$pgmasteruser" --env PGCLIENT_MASTER_IP="$pgmasterip" --env PGCLIENT_STANDBY_IP_LIST="$pgstandbyiplist"

echo "pgclient cartridge added"

echo "client configuration complete"

