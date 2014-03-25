#!/bin/bash

contextfile=~/jbossews/conf/context.xml
jbossews=~/pgclient/conf/tomcat7
newdatasources=$jbossews/context.xml

if [ -n "$OPENSHIFT_JBOSSEWS_IP" ];
then
        echo "configuring jbossews context.xml"
        if [ -f $contextfile ];
        then
                echo "jbossews context.xml found"
                erb $jbossews/context.xml.erb > $jbossews/context.xml
                sed '/<\/Context/i MARKER' $contextfile  | sed -e '/MARKER/r '$newdatasources -e '/MARKER/d'  >> $jbossews/pgclient-context.xml
        else
                echo "jbossews context.xml not found"
        fi
fi
~             
