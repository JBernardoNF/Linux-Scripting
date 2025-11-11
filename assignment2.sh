#!/bin/bash

# Assignment 2 Script
# This script will configure server1 as required
# It is idempotent and safe to run multiple times

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "===================================="
echo "Starting Assignment 2 configuration"
echo "===================================="

# Function to configure network
configure_network() {
    echo "Configuring network interface for 192.168.16.21..."

    NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

    # Backup original netplan file if not already backed up
    if [ ! -f "${NETPLAN_FILE}.bak" ]; then
        cp $NETPLAN_FILE ${NETPLAN_FILE}.bak
        echo "Backup of netplan created at ${NETPLAN_FILE}.bak"
    fi

    # Check if the IP is already set
    if grep -q "192.168.16.21/24" $NETPLAN_FILE; then
        echo "IP 192.168.16.21 already configured."
    else
        echo "Setting IP 192.168.16.21..."
        # Remove any existing 192.168.16.x address
        sed -i '/192\.168\.16\./d' $NETPLAN_FILE
        cat >> $NETPLAN_FILE <<EOL
ethernets:
    eth1:
        addresses: [192.168.16.21/24]
EOL
        netplan apply
        echo "IP configuration applied."
    fi

    # Ensure /etc/hosts is correct
    if grep -q "192.168.16.21" /etc/hosts; then
        echo "/etc/hosts already has correct entry."
    else
        sed -i '/server1/d' /etc/hosts
        echo "192.168.16.21 server1" >> /etc/hosts
        echo "/etc/hosts updated."
    fi
}

# Function to install Apache2 and Squid
install_services() {
    echo "Installing and configuring Apache2 and Squid..."

    # Apache2
    if ! dpkg -l | grep -q apache2; then
        echo "Apache2 not installed. Installing..."
        apt update
        apt install -y apache2
    else
        echo "Apache2 is already installed."
    fi
    systemctl enable apache2
    systemctl restart apache2
    echo "Apache2 service running."

    # Squid
    if ! dpkg -l | grep -q squid; then
        echo "Squid not installed. Installing..."
        apt install -y squid
    else
        echo "Squid is already installed."
    fi
    systemctl enable squid
    systemctl restart squid
    echo "Squid service running."
}

# Function to create user accounts
create_users() {
    echo "Creating user accounts..."

    USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            echo "User $user already exists."
        else
            echo "Creating user $user..."
            useradd -m -s /bin/bash "$user"
        fi

        SSH_DIR="/home/$user/.ssh"
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        chown "$user:$user" "$SSH_DIR"

        AUTH_KEYS="$SSH_DIR/authorized_keys"
        touch "$AUTH_KEYS"
        chmod 600 "$AUTH_KEYS"
        chown "$user:$user" "$AUTH_KEYS"

        # Special case: dennis gets predefined public key
        if [ "$user" == "dennis" ]; then
            if ! grep -q "AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI" "$AUTH_KEYS"; then
                echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "$AUTH_KEYS"
            fi
            usermod -aG sudo dennis
        fi
    done
}

# Call the functions
configure_network
install_services
create_users

echo "===================================="
echo "Assignment 2 configuration completed!"
echo "===================================="
