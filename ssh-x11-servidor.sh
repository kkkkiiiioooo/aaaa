#!/bin/sh
apk add openssh xauth firefox-esr
echo "X11Forwarding yes" >> /etc/ssh/sshd_config
rc-update add sshd
rc-service sshd start
