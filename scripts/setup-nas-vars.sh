#!/bin/bash
# Simple setup script for external variables on NAS via NFS

set -euo pipefail

VARIABLES_HOST="dawn.orbit"
VARIABLES_NFS_PATH="/mnt/nas/homelab/variables"
VARIABLES_NAS_PATH="/var/nfs/shared/homelab/variables"
VARIABLES_FILE="orbit-puppet.yaml"

echo "Setting up external variables on NAS via NFS..."

# Install NFS client if not present
if ! command -v mount.nfs &> /dev/null; then
    echo "Installing NFS client..."
    apt update && apt install -y nfs-common
fi

# Create NFS mount point
mkdir -p "$VARIABLES_NFS_PATH"

# Test NFS connectivity
echo "Testing NFS connectivity to $VARIABLES_HOST..."
if ! mount -t nfs "${VARIABLES_HOST}:${VARIABLES_NAS_PATH}" "$VARIABLES_NFS_PATH" 2>/dev/null; then
    echo "ERROR: Cannot mount NFS share from $VARIABLES_HOST"
    echo "Please ensure:"
    echo "1. NFS is enabled on your NAS"
    echo "2. The path ${VARIABLES_NAS_PATH} is shared"
    echo "3. This host has permission to mount the share"
    exit 1
fi

echo "✓ Successfully mounted NFS share"

# Check if variables file already exists
if [[ -f "${VARIABLES_NFS_PATH}/${VARIABLES_FILE}" ]]; then
    echo "Variables file already exists on NAS"
    echo "Current content:"
    cat "${VARIABLES_NFS_PATH}/${VARIABLES_FILE}"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing file"
        umount "$VARIABLES_NFS_PATH" 2>/dev/null || true
        exit 0
    fi
fi

# Create the variables file
echo "Creating orbit-puppet.yaml on NAS..."

# Get Discord webhook URL from user
read -p "Enter your Discord webhook URL (or press Enter to skip): " discord_webhook

# Create the file content directly on NFS mount
cat > "${VARIABLES_NFS_PATH}/${VARIABLES_FILE}" <<EOF
# External variables for orbit-puppet
# This file contains sensitive data and should not be committed to git

# Discord webhook for notifications
discord:
  webhook_url: "${discord_webhook:-REPLACE_WITH_YOUR_WEBHOOK_URL}"

# Docker Swarm tokens (will be auto-updated by manager node)
docker_swarm:
  manager_token: "WILL_BE_AUTO_POPULATED"
  worker_token: "WILL_BE_AUTO_POPULATED"

# Additional secrets as needed
# api_keys:
#   komodo_api_key: "your-api-key-here"
#   monitoring_token: "your-token-here"
EOF

echo "✓ External variables file created on NFS share"
echo "✓ File location: ${VARIABLES_NFS_PATH}/${VARIABLES_FILE}"

# Test reading the file
echo "Testing file access..."
if [[ -r "${VARIABLES_NFS_PATH}/${VARIABLES_FILE}" ]]; then
    echo "✓ Successfully created and can read variables file"
else
    echo "✗ Failed to read variables file"
    umount "$VARIABLES_NFS_PATH" 2>/dev/null || true
    exit 1
fi

# Unmount NFS share
umount "$VARIABLES_NFS_PATH" 2>/dev/null || true

echo ""
echo "Setup complete! The deploy script will now:"
echo "1. Mount NFS share and fetch external variables before each Puppet run"
echo "2. Send Discord notifications on failures or changes"
echo "3. Cache variables locally in case NFS is unavailable"
echo ""
echo "NFS share details:"
echo "  Host: $VARIABLES_HOST"
echo "  Share: $VARIABLES_NAS_PATH"
echo "  Mount point: $VARIABLES_NFS_PATH"
echo "  Variables file: $VARIABLES_FILE"
