#!/bin/bash

/sbin/ip route replace default via 10.0.1.254
mkdir -f /var/run/nagios
/usr/sbin/nrpe -c /etc/nagios/nrpe.cfg -d
/usr/sbin/named -g -c /etc/bind/named.conf -u bind
while true
 do
        /bin/sleep 1m
 done


