#!/bin/bash

/root/rename_if.sh

systemctl start zebra
systemctl start ospfd
/root/sleep.sh

