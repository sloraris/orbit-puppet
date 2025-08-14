#!/bin/bash
# Puppet deployment script for masterless setup

set -e

PUPPET_ENV=${PUPPET_ENV:-production}
REPO_URL=${REPO_URL:-"https://github.com/sloraris/orbit-puppet.git"}
PUPPET_DIR="/etc/puppet/code/environments/${PUPPET_ENV}"

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

# Install Puppet if not present
if ! command -v puppet &> /dev/null; then
    log "Installing Puppet..."
    wget https://apt.puppet.com/puppet7-release-$(lsb_release -cs).deb
    dpkg -i puppet7-release-$(lsb_release -cs).deb
    apt-get update
    apt-get install -y puppet-agent
    rm puppet7-release-$(lsb_release -cs).deb
fi

# Install r10k if not present
if ! command -v r10k &> /dev/null; then
    log "Installing r10k..."
    gem install r10k
fi

# Create puppet directory if it doesn't exist
mkdir -p "$PUPPET_DIR"

# Clone or update repository
if [ -d "$PUPPET_DIR/.git" ]; then
    log "Updating Puppet configuration from Git..."
    cd "$PUPPET_DIR"
    git pull origin main
else
    log "Cloning Puppet configuration from Git..."
    git clone "$REPO_URL" "$PUPPET_DIR"
    cd "$PUPPET_DIR"
fi

# Install external modules
log "Installing external modules with r10k..."
r10k puppetfile install

# Set proper permissions
chown -R root:root "$PUPPET_DIR"
chmod -R 755 "$PUPPET_DIR"

# Run Puppet
log "Running Puppet apply..."
puppet apply \
    --confdir=/etc/puppet \
    --vardir=/var/cache/puppet \
    --environment="$PUPPET_ENV" \
    --environmentpath="/etc/puppet/code/environments" \
    --detailed-exitcodes \
    manifests/site.pp

exit_code=$?

case $exit_code in
    0)
        log "Puppet run completed successfully - no changes made"
        ;;
    2)
        log "Puppet run completed successfully - changes were made"
        ;;
    *)
        error "Puppet run failed with exit code $exit_code"
        ;;
esac

log "Deployment completed successfully!"
