#!/bin/bash
#
/root/rename_if.sh

systemctl start zebra
systemctl start ospfd
systemctl start bgpd
/root/sleep.sh

