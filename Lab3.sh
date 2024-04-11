#!/bin/bash

usage() {
    echo "Usage: $0 [-verbose]"
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -verbose)
        VERBOSE=true
        shift
        ;;
        *)
        usage
        ;;
    esac
done

VERBOSE=${VERBOSE:-false}

log() {
    local message="$1"
    if [ "$VERBOSE" = true ]; then
        echo "$message"
    fi
}

log "Transferring configure-host.sh to server1-mgmt..."
scp configure-host.sh remoteadmin@server1-mgmt:/root || { echo "Error: Failed to transfer configure-host.sh to server1-mgmt."; exit 1; }
log "Running configure-host.sh on server1-mgmt..."
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -verbose -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 || { echo "Error: Failed to run configure-host.sh on server1-mgmt."; exit 1; }

log "Transferring configure-host.sh to server2-mgmt..."
scp configure-host.sh remoteadmin@server2-mgmt:/root || { echo "Error: Failed to transfer configure-host.sh to server2-mgmt."; exit 1; }
log "Running configure-host.sh on server2-mgmt..."
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -verbose -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 || { echo "Error: Failed to run configure-host.sh on server2-mgmt."; exit 1; }

log "Updating local /etc/hosts file..."
./configure-host.sh -verbose -hostentry loghost 192.168.16.3 || { echo "Error: Failed to update local /etc/hosts file."; exit 1; }
./configure-host.sh -verbose -hostentry webhost 192.168.16.4 || { echo "Error: Failed to update local /etc/hosts file."; exit 1; }

log "Configuration completed successfully."
exit 0
