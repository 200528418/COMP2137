#!/bin/bash


# This script is for assignment 2 submission by 200528418(Harmanjot)

#To make script robust, I am using some functions
# log actions function
log() {
    echo "[INFO] $1"
}

# Function for log errors
error() {
    echo "[ERROR] $1" >&2
}

#this  Function will check that if a line exists in a file
line_exists() {
    grep -Fxq "$1" "$2"
}

# To update network configuration as per given instructions
update_network_config() {
    log "Updating network configuration..."
    # Check if configuration already exists
    if ! grep -q "192.168.16.21" /etc/netplan/*.yaml; then
        sed -i 's/192.168.16.2/192.168.16.21/' /etc/netplan/*.yaml || { error "Failure to update network configuration"; return 1; }
        netplan apply || { error "Failed to apply network configuration"; return 1; }
        log "New Network configuration updated."
    else
        log "This Network configuration already up to date."
    fi
}

# To update hosts file
update_hosts_file() {
    log "As per assignment instructions, Adding server1 to /etc/hosts file if necessary..."
    if line_exists "192.168.16.21 server1" /etc/hosts; then
        log "Cannot update as Hosts file is already up to date."
    else
        sed -i '/server1/d' /etc/hosts && \
        echo "192.168.16.21 server1" >> /etc/hosts || { error "Failed to update hosts file"; return 1; }
        log "Hosts file updated."
    fi
}

#This Function will try to install required software
install_software() {
    log "Installing required software..."
    if ! dpkg -s apache2 squid &> /dev/null; then
        apt-get update || { error "Failed to update package repositories"; return 1; }
        apt-get install -y apache2 squid || { error "Failed to install software"; return 1; }
        systemctl enable apache2 squid || { error "Failed to enable services"; return 1; }
        systemctl start apache2 squid || { error "Failed to start services"; return 1; }
        log "Software installed and services started."
    else
        log "Software already installed."
    fi
}

#configure firewall for assignment
configure_firewall() {
    log "Configuring firewall..."
    ufw allow in on eth2 to any port 22 || { error "Failed to allow SSH on mgmt network"; return 1; }
    ufw allow in on eth0 to any port 80 || { error "Failed to allow HTTP on eth0"; return 1; }
    ufw allow in on eth1 to any port 80 || { error "Failed to allow HTTP on eth1"; return 1; }
    ufw allow in on eth0 to any port 3128 || { error "Failed to allow web proxy on eth0"; return 1; }
    ufw allow in on eth1 to any port 3128 || { error "Failed to allow web proxy on eth1"; return 1; }
    ufw --force enable || { error "Failed to enable firewall"; return 1; }
    log "Firewall configured."
}

# Creating user accounts as per assignment instructions
create_user_accounts() {
    log "Creating Requested user accounts..."
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user" || { error "Failed to create user '$user'"; continue; }
            if [ -f "/home/remoteadmin/.ssh/id_rsa.pub" ]; then
                mkdir -p "/home/$user/.ssh" && \
                cp "/home/remoteadmin/.ssh/id_rsa.pub" "/home/$user/.ssh/authorized_keys" && \
                cp "/home/remoteadmin/.ssh/id_ed25519.pub" "/home/$user/.ssh/authorized_keys" && \
                chown -R "$user:$user" "/home/$user/.ssh" && \
                chmod 700 "/home/$user/.ssh" && \
                chmod 600 "/home/$user/.ssh/authorized_keys" && \
                log "SSH keys added for user '$user'."
            else
                error "Failed to copy SSH keys for user '$user'. SSH keys are not available."
            fi
        else
            log "User '$user' already exists."
        fi
    done
    usermod -aG sudo dennis || { error "Failed to grant sudo access to dennis"; return 1; }
    log "Sudo access granted to dennis."
}

# Main script
log "Starting configuration update..."
update_network_config && \
update_hosts_file && \
install_software && \
configure_firewall && \
create_user_accounts
if [ $? -eq 0 ]; then
    log "Configuration update complete."
    log "This script did his work successfully for the assignment 2"
else
    error "Failed to complete configuration update."
fi
