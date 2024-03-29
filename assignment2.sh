#!/bin/bash


update_hosts_file() {
    hostname="$1"
    ip_address="$2"
    if grep -q "$hostname" /etc/hosts; then
        sed -i "s/.*$hostname.*/$ip_address\t$hostname/" /etc/hosts
        echo "Updated /etc/hosts: $hostname -> $ip_address"
    else
        echo "$ip_address\t$hostname" >> /etc/hosts
        echo "Added entry to /etc/hosts: $hostname -> $ip_address"
    fi
}

add_ssh_keys() {
    username="$1"
    ssh_dir="/home/$username/.ssh"
    mkdir -p "$ssh_dir"
    echo "ssh-rsa <RSA_PUBLIC_KEY>" >> "$ssh_dir/authorized_keys"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "$ssh_dir/authorized_keys"
    echo "Added SSH keys for user: $username"
}

create_user_accounts() {
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "Created user account: $user"
            add_ssh_keys "$user"
        else
            echo "User account already exists: $user"
        fi
    done
}

configure_firewall() {
    ufw --force reset   # Reset firewall rules
    ufw default deny incoming   # Deny all incoming traffic by default
    ufw default allow outgoing   # Allow all outgoing traffic by default
    ufw allow in on ens192 to any port 22 proto tcp comment 'Allow SSH on management network'
    ufw allow in on ens160 to any port 80 proto tcp comment 'Allow HTTP on ens160'
    ufw allow in on ens160 to any port 3128 proto tcp comment 'Allow Squid proxy on ens160'
    ufw --force enable   # Enable the firewall with updated rules
    echo "Firewall configured"
}


main() {
    echo "Starting assignment2.sh script"

    update_hosts_file "server1" "192.168.16.21"
    create_user_accounts
    configure_firewall

    echo "Assignment2.sh script completed"
}

main
