#!/bin/sh

set -ex

if [ -e /gigastorage/agent.env ]; then
    . /gigastorage/agent.env ;
else
    exit -1;
fi

# Create the persistent k3s required dirs on a persistent fs
mkdir -p /gigastorage/var_lib_greatbear # && mkdir -p /var/lib/greatbear

# Mount bind the persistent dirs onto expected mountpoints
grep -qs '/var/lib/greatbear ' /proc/mounts || mount -obind /gigastorage/var_lib_greatbear /var/lib/greatbear
. /gigastorage/agent.env
/usr/bin/agent