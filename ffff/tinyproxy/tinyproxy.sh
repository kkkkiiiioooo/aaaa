#!/bin/sh
apk add tinyproxy
sed -i '/^Port /d;/^Listen /d' /etc/tinyproxy/tinyproxy.conf
cat "$(dirname "$0")/tinyproxy.conf" >> /etc/tinyproxy/tinyproxy.conf
rc-update add tinyproxy
rc-service tinyproxy start
