#!/bin/bash

source $OPENSHIFT_CARTRIDGE_SDK_BASH

cart_short_name=`primary_cartridge_short_name`

cart_ip_name=`primary_cartridge_private_ip_name`

ipaddressvar="OPENSHIFT_"$cart_short_name"_"$cart_ip_name

echo $ipaddressvar

echo ${!ipaddressvar}

