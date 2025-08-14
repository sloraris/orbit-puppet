# Orbit Puppet Infrastructure

This repository contains the Puppet configuration for ORBIT homelab, providing automated server provisioning and configuration management using a **masterless Puppet** approach.

## Architecture Overview

This setup uses **masterless Puppet** with:
- GitHub repository as the source of truth
- GitHub Actions for validation and CI/CD
- Each node pulls configuration directly from Git
- r10k for external module management
- Proper separation of external and custom modules

## Infrastructure Components

### Roles

- **base** - Basic server configuration with Docker and security hardening
- **swarm** - Docker Swarm worker node
- **swarm_manager** - Docker Swarm manager node
- **komodo_core** - Komodo core node configuration
- **komodo_periphery** - Komodo periphery node configuration

### Current Nodes

- **luna.orbit** - x86 machine (Swarm manager)
- **artemis.orbit** - Pi 5 (Swarm worker)
- **echo.orbit** - Pi 5 (Swarm worker)

## Module Structure

```
├── site-modules/          # Custom modules (tracked in Git)
│   ├── base_server/       # Base server configuration
│   └── komodo/           # Komodo application deployment
├── modules/              # External modules (installed by r10k, not tracked)
│   ├── docker/           # Official puppetlabs-docker module
│   ├── apt/              # APT package management
│   ├── ufw/              # UFW firewall management
│   └── ...               # Other external dependencies
├── manifests/            # Main site manifest
├── data/                 # Hiera data files
└── scripts/              # Deployment and utility scripts
```

## Quick Start

### Initial Setup on a New Node

1. **Run the deployment script**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/your-username/orbit-puppet/main/scripts/deploy.sh | sudo bash
   ```

2. **Setup automatic updates** (optional):
   ```bash
   sudo /etc/puppet/code/environments/production/scripts/setup-cron.sh
   ```

### Manual Deployment

1. **Clone the repository**:
   ```bash
   sudo git clone https://github.com/your-username/orbit-puppet.git /etc/puppet/code/environments/production
   cd /etc/puppet/code/environments/production
   ```

2. **Install external modules**:
   ```bash
   sudo /opt/puppetlabs/puppet/bin/r10k puppetfile install
   ```

3. **Run Puppet**:
   ```bash
   sudo /opt/puppetlabs/bin/puppet apply --environment=production --environmentpath=/etc/puppet/code/environments manifests/site.pp
   ```

## Configuration

### Adding a New Node

1. Create a new file in `data/nodes/` named `<hostname>.yaml`:
   ```yaml
   roles:
     - base
     - swarm  # or swarm_manager for the manager node
   ```

2. Commit and push the changes
3. Run the deployment script on the new node

### Adding a New Role

1. Define the role in `data/roles.yaml`:
   ```yaml
   role_classes:
     my_new_role:
       classes:
         - my_module::my_class
       ports:
         - port: 8080
           protocol: tcp
           source: lan
   ```

2. Create the corresponding module in `site-modules/`
3. Assign the role to nodes in their respective YAML files

### Hiera Data Structure

The configuration uses Hiera 5 with this hierarchy:

1. **Per-node data** (`data/nodes/<hostname>.yaml`) - Node-specific configurations
2. **Role definitions** (`data/roles.yaml`) - Role-based class and port definitions
3. **Global settings** (`data/global.yaml`) - Shared configuration across all nodes

## Security Features

- **SSH key-based authentication** (pulls keys from GitHub)
- **UFW firewall** with role-based port management
- **User management** with restricted access
- **Docker security** with proper user group management

## Network Configuration

### Required Ports (automatically managed)

- **SSH**: 22/tcp (LAN only)
- **Docker Swarm**: 7946/tcp+udp, 4789/udp (LAN only)
- **Swarm Manager**: 2377/tcp (LAN only)
- **Komodo**: 8120/tcp (configurable)

## CI/CD Pipeline

GitHub Actions automatically:
- Validates Puppet syntax
- Lints Puppet code
- Validates Hiera YAML files
- Runs on every push and pull request

## Docker Swarm Setup

Docker Swarm is managed using the official `puppetlabs-docker` module with the following configuration:

### Manager Node (luna.orbit)
- Automatically initializes the swarm cluster
- Configured via `docker::swarm_init: true` in node data
- Advertises on the specified IP address

### Worker Nodes (artemis.orbit, echo.orbit)
- Automatically join the swarm cluster
- Configured via `docker::swarm_join: true` in node data
- Connect to the manager IP specified in configuration

### Manual Override
If automatic join fails, you can still manually join workers:
```bash
# On manager node
docker swarm join-token worker

# On worker nodes
docker swarm join --token <token> <manager-ip>:2377
```

## Troubleshooting

### Check Puppet Logs
```bash
sudo tail -f /var/log/puppet-cron.log
```

### Manual Puppet Run with Debug
```bash
sudo /opt/puppetlabs/bin/puppet apply --debug --environment=production --environmentpath=/etc/puppet/code/environments manifests/site.pp
```

### Validate Configuration
```bash
# Check syntax
find manifests site-modules -name "*.pp" -exec puppet parser validate {} \;

# Check Hiera data
find data -name "*.yaml" -exec ruby -ryaml -e "YAML.load_file('{}'); puts 'Valid: {}'" \;
```

## Development

### Local Testing
1. Fork the repository
2. Make changes in a feature branch
3. GitHub Actions will validate your changes
4. Test on a development node before merging

### Module Development
- Custom modules go in `site-modules/`
- Follow Puppet best practices
- Include proper error handling and idempotency
- Document any new roles or configuration options

## Support

For issues or questions:
1. Check the GitHub Actions logs for validation errors
2. Review Puppet logs on the affected nodes
3. Ensure all required ports are open between nodes
4. Verify Hiera data syntax and structure
