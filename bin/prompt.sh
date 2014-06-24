

#####################################################################
currentname=`rhc domain list | head -1 | cut -f 2 -d " "`

defaultdomain="example.com"
echo -n "enter your domain name ["$defaultdomain"]:"
read domainname

if [[ -z $domainname ]];
	then domainname=$defaultdomain;
fi

echo -n "enter your openshift domain name ["$currentname"]:"
read openshiftdomain
if [[ -z $openshiftdomain ]];
	then openshiftdomain=$currentname;
fi

defaultmastername="pgmaster"
echo -n "enter the name of the postgres master app ["$defaultmastername"]:"
read pgmastername
if [[ -z $pgmastername ]];
    then pgmastername=$defaultmastername;
fi

defaultwebframework="php-5.3"
echo -n "enter the web framework to use ["$defaultwebframework"]:"
read webframework
if [[ -z $webframework ]];
    then webframework=$defaultwebframework;
fi

defaultstandbygearprofile="small"
gearsizes=`rhc domain show  | grep Allowed | cut -d ":" -f 2 | tr -d ' '`
OIFS=$IFS
IFS=","
gearsArray=($gearsizes)
echo "Valid gear sizes are: "
for ((i=0; i<${#gearsArray[@]}; ++i));
do
	echo "${gearsArray[$i]}";
done
IFS=$OIFS;
echo -n "enter the pg standby gear profile to use ["$defaultstandbygearprofile"]:"
read standbygearprofile
if [[ -z $standbygearprofile ]];
    then standbygearprofile=$defaultstandbygearprofile;
fi
for ((i=0; i<${#gearsArray[@]}; ++i));
do
	if [[ ${gearsArray[$i]} == $standbygearprofile ]]; then
		validgearused="true"
	fi
done

if [[ -z $validgearused ]];
	then echo "error:  you did not enter a valid gear size" && exit;
fi

###################################################################

