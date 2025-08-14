#!/bin/bash
# Script to convert a Puppet agent node to masterless

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

log "Converting Puppet agent to masterless setup..."

# Stop and disable puppet agent
if systemctl is-active --quiet puppet; then
    log "Stopping Puppet agent service..."
    systemctl stop puppet
fi

if systemctl is-enabled --quiet puppet; then
    log "Disabling Puppet agent service..."
    systemctl disable puppet
fi

# Clean up puppet.conf to remove master references
log "Cleaning up Puppet configuration..."
if [ -f /etc/puppet/puppet.conf ]; then
    # Backup original config
    cp /etc/puppet/puppet.conf /etc/puppet/puppet.conf.backup

    # Remove master-related settings
    sed -i '/^server = /d' /etc/puppet/puppet.conf
    sed -i '/^ca_server = /d' /etc/puppet/puppet.conf
    sed -i '/^facts_terminus = yaml/d' /etc/puppet/puppet.conf

    # Ensure we have the basic settings for masterless
    if ! grep -q "^certname = " /etc/puppet/puppet.conf; then
        echo "certname = $(hostname -f)" >> /etc/puppet/puppet.conf
    fi
fi

# Clean up SSL certificates from agent setup
if [ -d /var/lib/puppet/ssl ]; then
    log "Removing old SSL certificates..."
    rm -rf /var/lib/puppet/ssl
fi

# Clean up cached catalogs
if [ -d /var/cache/puppet ]; then
    log "Cleaning Puppet cache..."
    rm -rf /var/cache/puppet/*
fi

log "Puppet agent cleanup completed!"
log "You can now run the masterless deployment script."
