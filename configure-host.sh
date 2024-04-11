#!/bin/bash

log_changes() {
    [ "$VERBOSE" = true ] && echo "$1"
    logger -t configure-host "$1"
}

update_hostname() {
    local new_hostname="$1"
    current_hostname=$(hostname)
    
    if [ "$new_hostname" != "$current_hostname" ]; then
        sudo hostnamectl set-hostname "$new_hostname" && log_message "Hostname updated to $new_hostname"
    else
        log_changes "Hostname is already set to $new_hostname"
    fi
}

log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> /var/log/hostname_change.log
}

update_ip() {
    local new_ip="$1"
    local current_ip=$(hostname -I | awk '{print $1}')
    if [ "$new_ip" != "$current_ip" ]; then
        sed -i "/$current_ip/d" /etc/hosts
        sed -i "s/address .*/address $new_ip/g" /etc/netplan/*.yaml
        netplan apply && log_changes "IP address updated to $new_ip"
    else
        log_changes "IP address is already set to $new_ip"
    fi
}

update_host_entry() {
    local desired_name="$1"
    local desired_ip="$2"
    if grep -q "$desired_name" /etc/hosts; then
        log_changes "Host entry already exists for $desired_name with IP $desired_ip"
    else
        echo "$desired_ip    $desired_name" | sudo tee -a /etc/hosts >/dev/null && log_changes "Host entry added for $desired_name with IP $desired_ip"
    fi
}

trap '' TERM HUP INT

# Default values
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -verbose)
        VERBOSE=true
        shift
        ;;
        -name)
        update_hostname "$2"
        shift
        shift
        ;;
        -ip)
        update_ip "$2"
        shift
        shift
        ;;
        -hostentry)
        update_host_entry "$2" "$3"
        shift
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

exit 0
