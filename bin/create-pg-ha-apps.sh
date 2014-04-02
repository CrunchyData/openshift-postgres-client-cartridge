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

defaultstandbyname="pgstandby"
echo "enter the name of the postgres standby app ["$defaultstandbyname"]:"
read pgstandbyname
if [[ -z $pgstandbyname ]];
    then pgstandbyname=$defaultstandbyname;
fi

echo "cleaning up previous installs...."
pgmasterhostname=$pgmastername-$openshiftdomain.$domainname
pgstandbyhostname=$pgstandbyname-$openshiftdomain.$domainname

ssh-keygen -R $pgmasterhostname
ssh-keygen -R $pgstandbyhostname

rhc app-delete -a $pgmastername --confirm
rhc app-delete -a $pgstandbyname --confirm

/bin/rm -rf $pgmastername
/bin/rm -rf $pgstandbyname

defaultwebframework="php-5.3"
echo "enter the web framework to use ["$defaultwebframework"]:"
read webframework
if [[ -z $webframework ]];
    then webframework=$defaultwebframework;
fi

rhc create-app -a $pgmastername -t $webframework
echo $pgmastername " created..."

rhc create-app -a $pgstandbyname -t $webframework -g standby
echo $pgstandbyname " created..."

#force a key to be added to your local known_hosts file
rhc ssh -a $pgmastername --command 'date'
rhc ssh -a $pgstandbyname --command 'date'

#now, get the keys for the pg servers from the local_hosts file
#and build a custom known_hosts file
rm ./pg_known_hosts
touch ./pg_known_hosts
chmod 600 ./pg_known_hosts
ssh-keygen -F $pgmasterhostname >> ./pg_known_hosts
ssh-keygen -F $pgstandbyhostname >> ./pg_known_hosts

#now, copy the pg known_hosts to the targets
rhc scp $pgmastername upload ./pg_known_hosts .openshift_ssh/known_hosts
rhc scp $pgstandbyname upload ./pg_known_hosts .openshift_ssh/known_hosts

#rhc create-app -a pgstandby -t php-5.3 -g node2profile

echo "generating pg apps key...."
/bin/rm pg_rsa_key*

ssh-keygen -f pg_rsa_key -N ''

echo "removing openshift domain key..."
rhc sshkey remove -i pg_key

echo "adding key to openshift domain...."
rhc sshkey add -i pg_key -k ./pg_rsa_key.pub

echo "copying key to servers...."
rhc scp $pgmastername upload pg_rsa_key .openshift_ssh/pg_rsa_key
rhc scp $pgstandbyname upload pg_rsa_key .openshift_ssh/pg_rsa_key

rhc add-cartridge crunchydatasolutions-pg-1.0 -a $pgmastername --env PG_NODE_TYPE=master
echo "added Crunchy postgres cartridge to "$pgmastername

echo "crunchy postgres cartridge added to " $pgmastername

rhc add-cartridge crunchydatasolutions-pg-1.0 -a $pgstandbyname --env PG_NODE_TYPE=standby
echo "crunchy postgres cartridge added to " $pgstandbyname

echo "stopping postgres on both servers..."

rhc ssh -a $pgmastername --command '~/pg/bin/control stop'
rhc ssh -a $pgstandbyname --command '~/pg/bin/control stop'
sleep 7

rhc ssh -a $pgmastername --command '~/pg/bin/configure.sh'
echo "configured master for replication.."

rhc ssh -a $pgmastername --command '~/pg/bin/control start'
echo "started master..."
sleep 7

rhc ssh -a $pgstandbyname --command '~/pg/bin/standby_replace_data.sh'
echo "created backup for standby server..."

rhc ssh -a $pgstandbyname --command '~/pg/bin/control start'
sleep 7
echo "started standby server...."
echo "replication setup complete"

