#!/bin/bash -x

# Script to prepare AWS instance for cloning
# Based on 
# K44134742: Considerations when cloning a BIG-IP virtual edition instance
# https://support.f5.com/csp/article/K44134742
# With a couple of additions/enhancements for Cloud VE:
# 1NIC + Resetting Cloud-Init 

# Wait until MCPD is up
# source /usr/lib/bigstart/bigip-ready-functions
# wait_bigip_ready

# Stop MCPD so won't overwrite /etc/sysconfig/network before shutdown
bigstart stop mcpd
# give mcpd time to shutdown
sleep 10
# rm db binary backup
rm -f /var/db/mcpdb* 

# Remove BIG-IP Network Artifacts from original 1NIC boot
# Restore Default DB Configs
rm -f /config/bigip.conf*
rm -f /config/bigip_base.conf*
cp /usr/share/defaults/bigip_base.conf /config/bigip_base.conf 
cp /usr/share/defaults/BigDB.dat.virtual /config/BigDB.dat
cp /defaults/fs/etc/confpp.dat /etc/confpp.dat


# Remove Linux Network Artifacts from 1st Boot
# sed -i -e 's/HOSTNAME=.*/HOSTNAME=None/g' /etc/sysconfig/network
# sed -i -e 's/GATEWAY=.*/GATEWAY=None/g' /etc/sysconfig/network
rm -f /etc/sysconfig/network
rm -f /var/lib/dhclient/dhclient.leases 

# Misc BIG-IP Artifacts

# From: https://support.f5.com/csp/article/K44134742
rm -f /config/f5-rest-device-id
# Remove SSH keys
rm -f /config/ssh/ssh_host_* 
rm -f /shared/ssh/ssh_host_*
# Remove any user keys
rm -f /home/admin/.ssh/authorized_keys

# reset the device administrative account passwords to their default values
echo "root:default" | chpasswd
echo "admin:admin" | chpasswd

# Remove master key
rm -fr /config/bigip/kstore/master

# Remove License(s) if any
rm -f /config/bigip.license*

# Reset VE
touch /.vadc_first_boot
touch /.vadc_fetch_keys

# Reset Cloud Agent
# AWS: Reset cloud-init so it starts up again
cloud-init clean --logs

# Optinally clean up logs
rm -rf /var/log/*

#shutdown -h now
exit 0