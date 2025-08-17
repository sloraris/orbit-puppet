#!/bin/bash
# Script to safely disable UFW and prepare for iptables management

echo "Disabling UFW and preparing for iptables..."

# Stop and disable UFW
sudo ufw --force reset
sudo systemctl stop ufw
sudo systemctl disable ufw

# Install iptables-persistent if not already installed
sudo apt-get update
sudo apt-get install -y iptables-persistent

# Clear any existing UFW rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# Set default policies (allow all for now, Puppet will manage)
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# Save the clean state
sudo netfilter-persistent save

echo "UFW disabled and iptables reset. Ready for Puppet management."
echo "Run your Puppet deployment to apply the new firewall rules."
