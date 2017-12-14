#!/bin/bash -x

# Load Default Config instead
# tmsh load /sys config default

# Remove Network Artifacts from original boot
tmsh modify sys global-settings hostname none
tmsh modify sys dns name-servers replace-all-with {}
tmsh modify sys dns search replace-all-with {}
tmsh delete sys management-route default
tmsh delete net route default
tmsh delete net self /Common/self_1nic
tmsh delete net vlan internal

# Provision ASM
# If loading default config, wait for mcpd again
# bash /var/tmp/wait-for-bigip.sh
# Othewise, get 01071003:3: A previous provisioning operation is in progress. Try again when the BIGIP is active.
tmsh modify sys provision asm level nominal

# Save to disk
tmsh save /sys config

# http://clouddocs.f5.com/cloud/public/v1/aws/AWS_autoscaling.html#awsasremovelicense
tmsh run util finalize-custom-ami

# Stop MCPD so won't overwrite /etc/sysconfig/network before shutdown
bigstart stop mcpd
rm -f /var/db/mcpdb*

# https://support.f5.com/csp/article/K44134742
rm -f /config/f5-rest-device-id

# Remove gateway from files
cp /var/tmp/confpp.dat /etc/confpp.dat
cp /usr/share/defaults/BigDB.dat.virtual /config/BigDB.dat

rm -f /etc/sysconfig/network

# Remove cloud-init so it starts up again
rm -f /etc/cloud/.cloud.dat
rm -fr /opt/cloud/*

# Optinally clean up logs
# rm -rf /var/log/*


exit 0