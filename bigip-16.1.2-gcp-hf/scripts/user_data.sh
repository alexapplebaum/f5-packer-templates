#!/bin/bash

# Send output to log file and serial console
mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads
LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

# Work around for password change prompt in 16.x
# Wa-Agent doesn't allow admin and custom user needs to be used, which requires password change.
# Need to change password even to allow Packer to login via SSH Key Auth 

# Warning: Permanently added '168.62.205.89' (ECDSA) to the list of known hosts.
# You are required to change your password immediately (root enforced)
#Last login: Wed Jul 27 11:57:50 2022 from 104.219.105.84
# Changing password for admin.
# (current) BIG-IP password: 

echo "Script Start: $(date)"
# Wait until MCPD is up
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

echo "Setting Password via tmsh: $(date)"
tmsh modify auth user admin password TempPaSsWd%4353

tmsh save /sys config

# echo "Setting Password via Rest: $(date)"
# curl -sk -u admin: -H "Content-Type: application/json" -X PATCH https://localhost:8100/mgmt/tm/auth/user/admin -d '{ "password": "TempPaSsWd%4354" }'

# Hack for https://github.com/rubenst2013/packer-boxes/commit/4b535fe2d544f4071c49ee97e425885a17366daf
# tmsh modify sys sshd port 2222
# tmsh stop /sys service sshd
# tmsh start /sys service sshd
# Kills Packer's Exsisting Initial SSH session to force another connection that doesn't get the prompt
#  root     20123  4272  3 13:26 ?        Ss     0:05 sshd: admin@notty
PACKER_SSH_PID=$(ps -ef | grep 'sshd: admin@notty' | grep -v grep | awk '{print $2}')
echo "Killing Packer's Existing Initial SSH Connection: PID ${PACKER_SSH_PID}"
kill -6 ${PACKER_SSH_PID}


echo "Script End: $(date)"
