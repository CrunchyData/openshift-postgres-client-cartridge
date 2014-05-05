#!/bin/bash


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

# clean up master if already exists

pgmasterhostname=$pgmastername-$openshiftdomain.$domainname
ssh-keygen -R $pgmasterhostname
rhc app-delete -a $pgmastername --confirm
/bin/rm -rf $pgmastername

rhc create-app -a $pgmastername -t $webframework
echo $pgmastername " created..."

echo "adding Crunchy postgres cartridge to "$pgmastername
rhc add-cartridge crunchydatasolutions-pg-1.0 -a $pgmastername --env PG_NODE_TYPE=master
rhc ssh -a $pgmastername --command '~/pg/bin/control stop'
echo "adding Crunchy HA cartridge to "$pgmastername
rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $pgmastername

#force a key to be added to your local known_hosts file
rhc ssh -a $pgmastername --command 'date'

rm ./pg_known_hosts
touch ./pg_known_hosts
chmod 600 ./pg_known_hosts

#now, get the keys for the pg servers from the local_hosts file
#and build a custom known_hosts file
ssh-keygen -F $pgmasterhostname >> ./pg_known_hosts


# create a number of standby apps up to max of 5

standbyarray=()

COUNTER=0
while [ $COUNTER -lt 5 ] 
do
		defaultstandbyname="pgstandby"$COUNTER
		echo "enter the name of the postgres standby app ["$defaultstandbyname"] or 'end':"
		read pgstandbyname
		if [ -z $pgstandbyname ]; then 
			pgstandbyname=$defaultstandbyname
		fi

		if [ $pgstandbyname == "end" ]; then
			break
		fi

		# clean up previous app with same name if exists
		pgstandbyhostname=$pgstandbyname-$openshiftdomain.$domainname
		ssh-keygen -R $pgstandbyhostname
		rhc app-delete -a $pgstandbyname --confirm
		/bin/rm -rf $pgstandbyname
		echo "creating "$pgstandbyname
		rhc create-app -a $pgstandbyname -t $webframework -g standby
		echo $pgstandbyname " created..."
		echo "adding Crunchy postgres cartridge to "$pgstandbyname
		rhc add-cartridge crunchydatasolutions-pg-1.0 -a $pgstandbyname --env PG_NODE_TYPE=standby
		echo "adding Crunchy HA cartridge to "$pgstandbyname
		rhc add-cartridge crunchydatasolutions-pgclient-1.0 -a $pgstandbyname
		rhc ssh -a $pgstandbyname --command 'date'
		ssh-keygen -F $pgstandbyhostname >> ./pg_known_hosts
		standbyarray=( "${standbyarray[@]}" $defaultstandbyname )


		let "COUNTER=$COUNTER+1"
done

echo "standby servers are "${standbyarray[*]}

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
for standbyapp in  ${standbyarray[*]}
do
	echo "uploading keys to "$standbyapp
	rhc scp $standbyapp upload ./pg_known_hosts .openshift_ssh/known_hosts
	rhc scp $standbyapp upload pg_rsa_key .openshift_ssh/pg_rsa_key
	echo "stopping pg database on "$standbyapp
	rhc ssh -a $standbyapp --command '~/pg/bin/control stop'
done

echo "all postgres servers should be stopped at this point.."
sleep 2

echo "begin configuring postgres servers for replication.."

rhc ssh -a $pgmastername --command '~/pg/bin/configure.sh'
echo "configured master for replication.."

rhc ssh -a $pgmastername --command '~/pg/bin/control start'
echo "started master..."
sleep 4

echo "creating backup for standby servers..."
for standbyapp in  ${standbyarray[*]}
do
	echo "creating standby data for "$standbyapp
	rhc ssh -a $standbyapp --command '~/pg/bin/standby_replace_data.sh'
	sleep 4
	echo "starting pg database on "$standbyapp
	rhc ssh -a $standbyapp --command '~/pg/bin/control start'
done

echo "grant replication role on master to master user.."
rhc ssh -a $pgmastername --command '~/pgclient/bin/grant.sh'

echo "postgres replication setup complete"

