#!/bin/bash

source $OPENSHIFT_CARTRIDGE_SDK_BASH

moduledir=$OPENSHIFT_REPO_DIR/.openshift/config/modules
standalonefile=$OPENSHIFT_REPO_DIR/.openshift/config/standalone.xml
jbosseap=$OPENSHIFT_PGCLIENT_DIR/conf/jbosseap
newdatasources=$jbosseap/datasource.xml

if [ -n "$OPENSHIFT_JBOSSEAP_IP" ];
then
#	client_result "configuring jbosseap module for crunchy postgres";
#	cp -r $jbosseap/com $moduledir

    erb $jbosseap/datasource.xml.erb > $newdatasources
    sed '/<\/datasources/i MARKER' $standalonefile  | sed -e '/MARKER/r '$newdatasources -e '/MARKER/d'  >> $jbosseap/pgclient-standalone.xml
	cp $standalonefile $standalonefile.bak
#    cp $jbosseap/pgclient-standalone.xml $standalonefile
#	$OPENSHIFT_JBOSSEAP_DIR/bin/control restart
fi
