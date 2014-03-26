#!/bin/bash

source $OPENSHIFT_CARTRIDGE_SDK_BASH

contextfile=$OPENSHIFT_REPO_DIR/.openshift/config/context.xml
jbossews=~/pgclient/conf/tomcat7
newdatasources=$jbossews/context.xml

if [ -n "$OPENSHIFT_JBOSSEWS_IP" ];
then
        client_result "configuring jbossews context.xml";
        if [ -f $contextfile ];
        then
                client_result "jbossews context.xml found"
                erb $jbossews/context.xml.erb > $jbossews/context.xml
                sed '/<\/Context/i MARKER' $contextfile  | sed -e '/MARKER/r '$newdatasources -e '/MARKER/d'  >> $jbossews/pgclient-context.xml
                cp $contextfile $contextfile.bak
                cp $jbossews/pgclient-context.xml $contextfile
				cd ~/jbossews/bin && ./control restart
        else
                client_result "jbossews context.xml not found"
        fi
fi
