#!/bin/bash
# Start Nagios
/etc/init.d/nagios start
# Change default route
/sbin/ip route replace default via 172.16.123.142
#Start Apache
rm -rf /run/apache2/apache2.pid
. /etc/apache2/envvars
. /etc/default/apache-htcacheclean
/usr/sbin/apache2 -DFOREGROUND
