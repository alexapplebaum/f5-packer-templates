#!/bin/bash -x

# Script to prepare Azure instance for cloning
# Based on 
# K44134742: Considerations when cloning a BIG-IP virtual edition instance
# https://support.f5.com/csp/article/K44134742
# With a couple of additions/enhancements for Cloud VE:
# 1NIC + Resetting Cloud-Init 

# If tmsh commands, need to wait until MCPD is up
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

# Delete Packer User
tmsh delete auth user packeruser

# tmsh modify sys sshd port 22
tmsh save /sys config

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
# skipping as cloud images have no default password
# echo "root:default" | chpasswd
# echo "admin:admin" | chpasswd

# Remove master key
rm -fr /config/bigip/kstore/master

# Remove License(s) if any
rm -f /config/bigip.license*

# Reset VE
touch /.vadc_first_boot
touch /.vadc_fetch_keys

# RESET CLOUD AGENTS

# Reset cloud-init so it starts up again
# https://cloudinit.readthedocs.io/en/latest/topics/cli.html

cloud-init clean --logs

# Reset wa-agent so it starts up again
# https://github.com/Azure/WALinuxAgent#commands
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-centos
# https://www.packer.io/plugins/builders/azure/arm#linux

waagent -force -deprovision+user
# Bug in deprovision so doesn't finish
# BZID: 1133521
# So Delete manually
rm -f /var/lib/waagent/provisioned
rm -f /var/lib/waagent/ovf-env.xml
rm -f /var/lib/waagent/CustomData


# Optinally clean up logs
# rm -f /var/log/waagent.log
rm -rf /var/log/*

rm -f ~/.bash_history
export HISTSIZE=0

#shutdown -h now
exit 0