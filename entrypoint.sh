#!/bin/bash
yes "" | sensors-detect
exec 
/usr/sbin/squid -N -f /etc/squid/squid.conf
