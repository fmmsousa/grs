#!/bin/bash
systemctl start zebra
systemctl start ospfd
systemctl start bgpd
/root/sleep.sh

