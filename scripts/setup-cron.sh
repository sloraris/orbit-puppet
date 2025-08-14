#!/bin/bash
# Setup cron job for automatic Puppet runs

PUPPET_ENV=${PUPPET_ENV:-production}
PUPPET_DIR="/etc/puppet/code/environments/${PUPPET_ENV}"

# Create cron job for Puppet runs every 30 minutes
cat > /etc/cron.d/puppet-apply << EOF
# Puppet automatic configuration management
# Runs every 30 minutes
*/30 * * * * root cd ${PUPPET_DIR} && ${PUPPET_DIR}/scripts/deploy.sh >> /var/log/puppet-cron.log 2>&1
EOF

# Create log rotation for puppet cron log
cat > /etc/logrotate.d/puppet-cron << EOF
/var/log/puppet-cron.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

echo "Cron job setup complete. Puppet will run every 30 minutes."
echo "Check logs with: tail -f /var/log/puppet-cron.log"
