#!/bin/bash -x

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

defaultmastername="pgmaster"
echo "enter the name of the postgres master app ["$defaultmastername"]:"
read pgmastername
if [[ -z $pgmastername ]];
    then pgmastername=$defaultmastername;
fi

defaultwebframework="php-5.3"
echo "enter the web framework to use ["$defaultwebframework"]:"
read webframework
if [[ -z $webframework ]];
    then webframework=$defaultwebframework;
fi

# define a number of standby apps up to max of 5

standbyarray=()
fqdnstandbyarray=()
standbyportarray=()
COUNTER=0
standbyportnum=15001
while [ $COUNTER -lt 5 ] 
do
		defaultstandbyname="pgstandby"$COUNTER
		echo "enter the name of the postgres standby app ["$defaultstandbyname"] or 'end':"
		read pgstandbyname

		if [[ $pgstandbyname == "end" ]]; then
			break
		fi

		if [ -z $pgstandbyname ]; then 
			pgstandbyname=$defaultstandbyname
		fi

		standbyarray=( "${standbyarray[@]}" $defaultstandbyname )
		fqdnstandbyarray=( "${fqdnstandbyarray[@]}" $defaultstandbyname-$openshiftdomain.$domainname )
		standbyportarray=( "${standbyportarray[@]}" $standbyportnum )

		let "COUNTER=$COUNTER+1"
		let "standbyportnum=$standbyportnum+1"
done
echo standby servers are ${standbyarray[*]}
echo fqdn standby servers are ${fqdnstandbyarray[*]}
echo standby ports are ${standbyportarray[*]}

# clean up master if already exists

pgmasterhostname=$pgmastername-$openshiftdomain.$domainname
ssh-keygen -R $pgmasterhostname
rhc app-delete -a $pgmastername --confirm
/bin/rm -rf $pgmastername

rhc create-app -a $pgmastername -t $webframework
echo $pgmastername " created..."
pgmasteruser=`rhc ssh -a $pgmastername 'echo $USER' 2> /dev/null`
echo $pgmastername USER is $pgmasteruser
pgmasterdns=$pgmastername-$openshiftdomain.$domainname
echo $pgmasterdns is PG_MASTER_DNS

echo "adding Crunchy postgres cartridge to "$pgmastername
rhc add-cartridge crunchydatasolutions-pg-1.0 -a $pgmastername --env PG_NODE_TYPE=master  --env JEFF_PG_STANDBY_DNS_LIST="${fqdnstandbyarray[*]}" --env JEFF_PG_STANDBY_PORT_LIST="${standbyportarray[*]}"
pgmasterip=`rhc ssh -a $pgmastername 'echo $OPENSHIFT_PG_HOST' 2> /dev/null`
echo PG_MASTER_IP is $pgmasterip
rhc ssh -a $pgmastername '~/pg/bin/control stop'

echo "adding Crunchy HA cartridge to "$pgmastername
rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $pgmastername 

#force a key to be added to your local known_hosts file
rhc ssh -a $pgmastername 'date'

rm ./pg_known_hosts
touch ./pg_known_hosts
chmod 600 ./pg_known_hosts

#now, get the keys for the pg servers from the local_hosts file
#and build a custom known_hosts file
ssh-keygen -F $pgmasterhostname >> ./pg_known_hosts



standbyuserarray=()
cnt=${standbyarray[@]}
idx=0
for standbyapp in ${standbyarray[*]};
do
# clean up previous app with same name if exists
		pgstandbyhostname=$standbyapp-$openshiftdomain.$domainname
		ssh-keygen -R $pgstandbyhostname
		rhc app-delete -a $standbyapp --confirm
		/bin/rm -rf $standbyapp
#		echo "creating "$standbyapp
		rhc create-app -a $standbyapp -t $webframework -g standby --env JEFF_PG_MASTER_USER=$pgmasteruser --env JEFF_PG_MASTER_DNS=$pgmasterdns --env JEFF_PG_MASTER_IP=$pgmasterip --env JEFF_PG_TUNNEL_PORT=${standbyportarray[idx]}
		standbyuser=`rhc ssh -a $standbyapp 'echo $USER'` 2> /dev/null
#		echo standby user is $standbyuser
		standbyuserarray=( "${standbyuserarray[@]}" $standbyuser)
#		echo $standbyapp " created..."
#		echo "adding Crunchy postgres cartridge to "$standbyapp
		rhc add-cartridge crunchydatasolutions-pg-1.0 -a $standbyapp --env PG_NODE_TYPE=standby
#		echo "adding Crunchy HA cartridge to "$standbyapp
		rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $standbyapp
		rhc ssh -a $standbyapp 'date'
		ssh-keygen -F $pgstandbyhostname >> ./pg_known_hosts
		let "idx=$idx+1"
done

echo standby users are ${standbyuserarray[@]}
rhc env-set JEFF_PG_STANDBY_USER_LIST="`echo ${standbyuserarray[@]}`" --app $pgmastername

#now, copy the pg known_hosts to the targets
rhc scp $pgmastername upload ./pg_known_hosts .openshift_ssh/known_hosts

echo "generating pg apps key...."
/bin/rm pg_rsa_key*

ssh-keygen -f pg_rsa_key -N ''

echo "removing openshift domain key..."
rhc sshkey remove -i pg_key

echo "adding key to openshift domain...."
rhc sshkey add -i pg_key -k ./pg_rsa_key.pub

echo "copying key to servers...."
rhc scp $pgmastername upload pg_rsa_key .openshift_ssh/pg_rsa_key

cnt=${standbyarray[@]}
for standbyapp in  ${standbyarray[*]};
do
	echo uploading keys to $standbyapp
	rhc scp $standbyapp upload ./pg_known_hosts .openshift_ssh/known_hosts
	rhc scp $standbyapp upload pg_rsa_key .openshift_ssh/pg_rsa_key
	echo stopping pg database on $standbyapp
	rhc ssh -a $standbyapp '~/pg/bin/control stop'
done

echo all postgres servers should be stopped at this point..
sleep 2

echo begin configuring postgres servers for replication..

rhc ssh -a $pgmastername '~/pgclient/bin/configure.sh'
echo configured master for replication..

rhc ssh -a $pgmastername '~/pg/bin/control start'
echo "started master..."
sleep 4

echo "creating backup for standby servers..."
for standbyapp in  ${standbyarray[*]};
do
	rhc ssh -a $standbyapp '~/pgclient/bin/standby_replace_data.sh'
	sleep 4
	rhc ssh -a $standbyapp '~/pg/bin/control start'
done
rhc ssh -a $pgmastername '~/pgclient/bin/grant.sh'
echo "postgres replication setup complete"
