#!/bin/sh

set -ex

LOG_LEVEL="debug"
SB_API="https://nmngr-api.dev.gbear.scratch.eticloud.io/api/v1"

if [ -z "$API_KEY" ]; then
    API_KEY="vXtdRRCo4xE4A3"
fi

if [ -z "$HARDWARE_ID" ]; then
    HARDWARE_ID=$(tr -d '\0' </proc/device-tree/serial-number)
fi

if [ -z "$PLATFORM" ]; then
    PLATFORM="gbeos"
fi

wsdir=/var/lib/gbear
mkdir -p $wsdir

tee /etc/systemd/system/agent.service.env >/dev/null <<END
NODE_HARDWAREID=$HARDWARE_ID
NODEMANAGER_URL=$SB_API
NODEMANAGER_TOKEN=$API_KEY
NODE_PLATFORM=$PLATFORM
LOG_LEVEL=$LOG_LEVEL
AGENT_DATA_DIR=$wsdir
END

