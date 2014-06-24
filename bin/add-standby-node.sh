#!/bin/bash 

. ./prompt.sh

echo $pgmastername is the pgmastername var
origportlist=`rhc env-show PGCLIENT_STANDBY_PORT_LIST --app ${pgmastername} | cut -d "=" -f2` 
origportlist=`echo $origportlist` | cut -d "=" -f2
#echo $origportlist is original port list
echo "WARNING:  the following standby ports are already in use - " $origportlist

portsarray=(`echo $origportlist`)
cnt=${#portsarray[@]}
let "nexttolast=$cnt-1"
let "nextport=${portsarray[$nexttolast]}+1"

defaultport=$nextport
echo -n "enter the standby port to use ["$defaultport"]:"
read standbyportnum
if [[ -z $standbyportnum ]];
    then standbyportnum=$defaultport;
fi


defaultstandbyname="pgstandby"$standbyportnum
echo -n "enter the name of the postgres standby app ["$defaultstandbyname"]:"
read standbyapp
if [[ -z $standbyapp ]];
    then standbyapp=$defaultstandbyname;
fi

fqdnstandby=$standbyapp-$openshiftdomain.$domainname

# clean up previous app with same name if exists
pgstandbyhostname=$standbyapp
pgstandbydnsname=$standbyapp-$openshiftdomain.$domainname
ssh-keygen -R $standbyapp
rhc app-delete -a $standbyapp --confirm
/bin/rm -rf $standbyapp

echo "creating "$standbyapp
pgmasteruser=`rhc ssh -a $pgmastername 'echo $USER' 2> /dev/null`
pgmasterdns=$pgmastername-$openshiftdomain.$domainname
pgmasterip=`rhc ssh -a $pgmastername 'echo $OPENSHIFT_PG_HOST' 2> /dev/null`

rhc create-app -a $standbyapp -t $webframework -g $standbygearprofile --env PGCLIENT_MASTER_USER=$pgmasteruser --env PGCLIENT_MASTER_DNS=$pgmasterdns --env PGCLIENT_MASTER_IP=$pgmasterip --env PGCLIENT_TUNNEL_PORT=$standbyportnum
standbyuser=`rhc ssh -a $standbyapp 'echo $USER'` 2> /dev/null
echo $standbyapp " created..."

echo "adding Crunchy postgres cartridge to "$standbyapp
rhc add-cartridge crunchydatasolutions-pg-1.0 -a $standbyapp --env PG_NODE_TYPE=standby
standbyip=`rhc ssh -a $standbyapp 'echo $OPENSHIFT_PG_HOST'` 2> /dev/null
echo standby ip is $standbyip
echo "adding Crunchy HA cartridge to "$standbyapp
rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $standbyapp
rhc ssh -a $standbyapp 'date'
ssh-keygen -F $pgstandbydnsname >> ./pg_known_hosts

origdnslist=`rhc env-show PGCLIENT_STANDBY_DNS_LIST --app ${pgmastername} | cut -d "=" -f2`
newdnslist="${origdnslist} ${pgstandbydnsname}"
origuserlist=`rhc env-show PGCLIENT_STANDBY_USER_LIST --app ${pgmastername} | cut -d "=" -f2`
newuserlist="${origuserlist} ${standbyuser}"
origiplist=`rhc env-show PGCLIENT_STANDBY_IP_LIST --app ${pgmastername} | cut -d "=" -f2`
newiplist="${origiplist} ${standbyip}"
newportlist="${origportlist} ${standbyportnum}"
#echo "new user list=" $newuserlist
#echo "new ip list=" $newiplist
#echo "new port list=" $newportlist

rhc env-set PGCLIENT_STANDBY_DNS_LIST="`echo ${newdnslist}`" --app $pgmastername
rhc env-set PGCLIENT_STANDBY_USER_LIST="`echo ${newuserlist}`" --app $pgmastername
rhc env-set PGCLIENT_STANDBY_IP_LIST="`echo ${newiplist}`" --app $pgmastername
rhc env-set PGCLIENT_STANDBY_PORT_LIST="`echo ${newportlist}`" --app $pgmastername

#now, copy the pg known_hosts to the targets
rhc scp $pgmastername upload ./pg_known_hosts .openshift_ssh/known_hosts

###########################################################
#/bin/rm pg_rsa_key*

#ssh-keygen -f pg_rsa_key -N ''

#echo "removing openshift domain key..."
#rhc sshkey remove -i pg_key

#echo "adding key to openshift domain...."
#rhc sshkey add -i pg_key -k ./pg_rsa_key.pub

#echo "copying key to servers...."
#rhc scp $pgmastername upload pg_rsa_key .openshift_ssh/pg_rsa_key

###########################################################

echo uploading keys to $standbyapp
rhc scp $standbyapp upload ./pg_known_hosts .openshift_ssh/known_hosts
rhc scp $standbyapp upload pg_rsa_key .openshift_ssh/pg_rsa_key
echo stopping pg database on $standbyapp
rhc ssh -a $standbyapp '~/pg/bin/control stop'

echo all postgres servers should be stopped at this point..
sleep 2

echo begin configuring postgres servers for replication..

rhc ssh -a $pgmastername '~/pgclient/bin/configure.sh'
echo configured master for replication..

rhc ssh -a $pgmastername '~/pg/bin/control start'
echo "started master..."
sleep 4

echo "creating backup for standby servers..."
rhc ssh -a $standbyapp '~/pgclient/bin/standby_replace_data.sh'
sleep 4
rhc ssh -a $standbyapp '~/pg/bin/control start'

echo "postgres standby node setup complete"
