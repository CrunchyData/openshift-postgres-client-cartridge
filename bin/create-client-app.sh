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

defaultappname="pgclientapp"
echo "enter the name of the client app to create ["$defaultappname"]:"
echo "caution:  this script deletes the app if it already exists!!"
read clientname
if [[ -z $clientname ]];
    then clientname=$defaultappname;
fi

#
# perform cleanup if this client already existed
#
rhc app-delete -a $clientname --confirm
/bin/rm -rf $clientname

defaultwebframework="jbossews-2.0"
echo "enter the web framework to use ["$defaultwebframework"]:"
read webframework
if [[ -z $webframework ]];
    then webframework=$defaultwebframework;
fi

rhc create-app -a $clientname -t $webframework
echo $clientname " created..."

#force a key to be added to your local known_hosts file
rhc ssh -a $clientname --command 'date'

echo "copying key to servers...."

defaultknownpath=`pwd`/known_hosts
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

rhc scp $clientname upload $knownpath .openshift_ssh/known_hosts

rhc scp $clientname upload $keypath .openshift_ssh/pg_rsa_key

#
# now we are ready to install the client cartridge
#

echo "installing crunchy pgclient cartridge onto " $clientname

rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $clientname 

echo "pgclient cartridge added"

echo "client configuration complete"

