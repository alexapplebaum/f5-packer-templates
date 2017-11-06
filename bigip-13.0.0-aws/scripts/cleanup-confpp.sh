#!/bin/bash 

# Reset confpp.dat

sed -i -e 's/addr LT_IPADDR ".*"/addr LT_IPADDR ""/g' /etc/confpp.dat
sed -i -e 's/gateway LT_IPADDR ".*"/gateway LT_IPADDR ""/g' /etc/confpp.dat
sed -i -e 's/netmask LT_IPADDR ".*"/netmask LT_IPADDR ""/g' /etc/confpp.dat
sed -i -e 's/nameservers LT_IPADDR_LIST ".*"/nameservers LT_IPADDR_LIST ""/g' /etc/confpp.dat
sed -i -e 's/unix_config_dns.replace.search LT_STRING_LIST ".*"/unix_config_dns.replace.search LT_STRING_LIST ""/g' /etc/confpp.dat
sed -i -e 's/unix_config_sysconfignw.replace.hostname unix_config_syslog.replace.hostname LT_STRING ".*"/unix_config_sysconfignw.replace.hostname unix_config_syslog.replace.hostname LT_STRING ""/g' /etc/confpp.dat