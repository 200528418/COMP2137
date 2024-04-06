!/bin/bash


#This script is  created for assignment 2  for submission by 200528418(Harmanjot)

#I am using concept of functions to create it more robust

# Function for log actions, which will be used for handling errors messages

log() {
    echo "[INFO] $1"
}

# Function to log errors
error() {
    echo "[ERROR] $1" >&2
}

#this Function will check if a line exists in a file
line_exists() {
    grep -Fxq "$1" "$2"
}

#To update network configuration as per instructions
update_network_config() {
    log "Now Updating new  network configuration..."
    # Check if configuration already exists
    if ! grep -q "192.168.16.21" /etc/netplan/*.yaml; then
        sed -i 's/192.168.16.2/192.168.16.21/' /etc/netplan/*.yaml || { error "Failed to update network configuration"; return 1; }
        netplan apply || { error "Failure in applying new network configuration"; return 1; }
        log "New Network configuration updated."
    else
        log "Cannot apply, Network configuration already up to date."
    fi
}

# update hosts file for the configuration to work
update_hosts_file() {
    log "Adding server1 to /etc/hosts file if necessary..."
    if line_exists "192.168.16.21 server1" /etc/hosts; then
        log "Hosts file already up to date."
    else
        sed -i '/server1/d' /etc/hosts && \
        echo "192.168.16.21 server1" >> /etc/hosts || { error "Failed to update hosts file"; return 1; }
        log "Hosts file updated."
    fi
}

# This will install required software as per assignment instructions
install_software() {
    log "Installing requested required software..."
    if ! dpkg -s apache2 squid &> /dev/null; then
        apt-get update || { error "Failed to update package repositories"; return 1; }
        apt-get install -y apache2 squid || { error "Failed to install software"; return 1; }
        systemctl enable apache2 squid || { error "Failed to enable services"; return 1; }
        systemctl start apache2 squid || { error "Failed to start services"; return 1; }
        log "New Softwares installed and services started as per requested in assignment."
    else
        log "Skipping, Software already installed."
    fi
}

# for configuration of firewall
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

# We will create requested user accounts as per instructions
create_user_accounts() {
    log "Creating user accounts..."
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
log "Starting new configuration update..."
log "This script successfully did the assignment 2"
update

