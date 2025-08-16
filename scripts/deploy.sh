#!/bin/bash
# Puppet deployment script for masterless setup

PUPPET_ENV=${PUPPET_ENV:-production}
REPO_URL=${REPO_URL:-"https://github.com/sloraris/orbit-puppet.git"}
PUPPET_DIR="/etc/puppet/code/environments/${PUPPET_ENV}"

# External variables configuration
VARIABLES_HOST="dawn.orbit"
VARIABLES_NFS_PATH="/mnt/nas/homelab/variables"
VARIABLES_NAS_PATH="/var/nfs/shared/homelab/variables"
VARIABLES_FILE="orbit-puppet.yaml"
VARIABLES_CACHE="/var/cache/puppet/orbit-puppet.yaml"

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
    send_discord_notification "failure" "$1"
    exit 1
}

# Function to mount NFS and fetch external variables
fetch_external_vars() {
    log "Fetching external variables from NFS..."

    # Create cache directory
    mkdir -p "$(dirname "$VARIABLES_CACHE")"

    # Create NFS mount point
    mkdir -p "$VARIABLES_NFS_PATH"

    # Install NFS client if not present
    if ! command -v mount.nfs &> /dev/null; then
        log "Installing NFS client..."
        apt install -y nfs-common
    fi

    # Mount NFS share (unmount first if already mounted)
    if mountpoint -q "$VARIABLES_NFS_PATH"; then
        umount "$VARIABLES_NFS_PATH" 2>/dev/null || true
    fi

    # Mount the NFS share
    if mount -t nfs "${VARIABLES_HOST}:${VARIABLES_NAS_PATH}" "$VARIABLES_NFS_PATH" 2>/dev/null; then
        log "Successfully mounted NFS share"

        # Copy the variables file to cache
        if [[ -f "${VARIABLES_NFS_PATH}/${VARIABLES_FILE}" ]]; then
            cp "${VARIABLES_NFS_PATH}/${VARIABLES_FILE}" "$VARIABLES_CACHE"
            chmod 600 "$VARIABLES_CACHE"  # Restrict access to sensitive data
            log "Successfully fetched external variables"

            # Unmount NFS share
            umount "$VARIABLES_NFS_PATH" 2>/dev/null || true
            return 0
        else
            warn "Variables file not found on NFS share: ${VARIABLES_NFS_PATH}/${VARIABLES_FILE}"
            umount "$VARIABLES_NFS_PATH" 2>/dev/null || true
        fi
    else
        warn "Failed to mount NFS share from ${VARIABLES_HOST}"
    fi

    # Fallback to cached file
    if [[ -f "$VARIABLES_CACHE" ]]; then
        warn "Using cached external variables"
        return 0
    else
        warn "No external variables available (cached or fresh)"
        return 1
    fi
}

# Function to get value from external variables
get_external_var() {
    local key="$1"
    local default="${2:-}"

    if [[ -f "$VARIABLES_CACHE" ]]; then
        # Use Python to parse YAML if available
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import yaml
import sys
try:
    with open('$VARIABLES_CACHE', 'r') as f:
        data = yaml.safe_load(f) or {}

    keys = '$key'.split('.')
    result = data
    for k in keys:
        if isinstance(result, dict) and k in result:
            result = result[k]
        else:
            print('$default')
            sys.exit(0)
    print(result)
except:
    print('$default')
" 2>/dev/null
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Function to send Discord notification
send_discord_notification() {
    local status="$1"
    local details="${2:-}"
    local webhook_url

    webhook_url=$(get_external_var "discord.webhook_url")

    if [[ -z "$webhook_url" || "$webhook_url" == "null" ]]; then
        return 0  # No webhook configured, skip notification
    fi

    local hostname
    hostname=$(hostname -f)
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Set color and title based on status
    local color title
    case "$status" in
        "failure")
            color="15158332"  # Red
            title="🚨 Puppet Apply Failed"
            ;;
        "changes")
            color="52224"  # Green
            title="⚙️ Puppet Applied Changes"
            ;;
        "notices")
            color="16776960"  # Yellow/Orange
            title="⚠️ Puppet Applied With Notices"
            ;;
        *)
            return 0  # Don't send notifications for success with no changes
            ;;
    esac

    # Build JSON payload
    local json_payload
    json_payload=$(cat <<EOF
{
    "embeds": [{
        "title": "$title",
        "color": $color,
        "timestamp": "$timestamp",
        "fields": [
            {
                "name": "Host",
                "value": "$hostname",
                "inline": false
            }
EOF
    )

    # Add details if provided
    if [[ -n "$details" ]]; then
        # Truncate details if too long
        if [[ ${#details} -gt 1000 ]]; then
            details="${details:0:997}..."
        fi
        json_payload+=',
            {
                "name": "Details",
                "value": "```\n'"$details"'\n```",
                "inline": false
            }'
    fi

    json_payload+='
        ]
    }]
}'

    # Send the webhook
    curl -s -H "Content-Type: application/json" -d "$json_payload" "$webhook_url" >/dev/null 2>&1 || true
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Install Puppet if not present
if ! command -v puppet &> /dev/null; then
    log "Installing Puppet..."
    apt install -y puppet-agent
fi

# Install r10k if not present
if ! command -v r10k &> /dev/null; then
    log "Installing r10k..."
    apt install -y r10k
fi

# Install Python3 and PyYAML for external variables parsing
if ! command -v python3 &> /dev/null; then
    log "Installing Python3 for YAML parsing..."
    apt install -y python3 python3-yaml
fi

# Fetch external variables before running Puppet
fetch_external_vars

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
output=$(puppet apply \
    --confdir=/etc/puppet \
    --vardir=/var/cache/puppet \
    --environment="$PUPPET_ENV" \
    --environmentpath="/etc/puppet/code/environments" \
    --detailed-exitcodes \
    manifests/site.pp)
exit_code=$?

# Count message types
error_count=$(grep -c "^Error:" <<< "$output")
warning_count=$(grep -c "^Warning:" <<< "$output")
notice_count=$(grep -c "^Notice:" <<< "$output")

# Error preview (first 2 errors)
error_preview=""
if (( error_count > 0 )); then
    error_preview=$(grep "^Error:" <<< "$output" | head -n 2)
    if (( error_count > 2 )); then
        error_preview+="\n... see logs for full output"
    fi
fi

# Warning/notice preview (first 2 warnings or notices combined)
warn_notice_preview=""
if (( warning_count > 0 || notice_count > 0 )); then
    warn_notice_preview=$(grep -E "^(Warning:|Notice:)" <<< "$output" | head -n 2)
    if (( warning_count + notice_count > 2 )); then
        warn_notice_preview+="\n... see logs for full output"
    fi
fi

# Summary counts
summary="Errors: $error_count | Warnings: $warning_count | Notices: $notice_count"

case $exit_code in
    0)
        if (( error_count > 0 )); then
            log "Puppet run completed with errors but no changes (exit code 0) - $summary"
            send_discord_notification "failure" "$summary\n\n$error_preview"
        elif (( warning_count > 0 || notice_count > 0 )); then
            log "Puppet run completed with notices/warnings but no changes (exit code 0) - $summary"
            send_discord_notification "notices" "$summary\n\n$warn_notice_preview"
        else
            log "Puppet run completed successfully - no changes made"
            send_discord_notification "success" "$summary"
        fi
        ;;
    2)
        if (( error_count > 0 )); then
            log "Puppet run completed with errors after changes (exit code 2) - $summary"
            send_discord_notification "failure" "$summary\n\n$error_preview"
        elif (( warning_count > 0 || notice_count > 0 )); then
            log "Puppet run completed with notices/warnings after changes (exit code 2) - $summary"
            send_discord_notification "notices" "$summary\n\n$warn_notice_preview"
        else
            log "Puppet run completed successfully - changes were made"
            send_discord_notification "changes" "$summary"
        fi
        ;;
    *)
        if (( error_count > 0 )); then
            error "Puppet run failed with errors (exit code $exit_code) - $summary"
            send_discord_notification "failure" "$summary\n\n$error_preview"
        elif (( warning_count > 0 || notice_count > 0 )); then
            log "Puppet run failed but had notices/warnings (exit code $exit_code) - $summary"
            send_discord_notification "notices" "$summary\n\n$warn_notice_preview"
        else
            error "Puppet run failed with unknown issue (exit code $exit_code) - $summary"
            send_discord_notification "failure" "$summary"
        fi
        ;;
esac
