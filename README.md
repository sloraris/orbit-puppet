# Orbit Puppet Infrastructure

This repository contains the Puppet configuration for ORBIT, providing automated server provisioning and configuration management.

## Overview

This repository is designed to manage a distributed system with Docker Swarm clusters and Komodo nodes. It provides:

- **Base server configuration** with security hardening
- **Docker and Docker Swarm** management
- **Komodo** node configuration for docker stack deployment automation and management
- **Role-based** node classification
- **Hierarchical data** management with Hiera

## Infrastructure Components

### Roles

- **base** - Basic server configuration with Docker
- **swarm** - Docker Swarm worker node
- **swarm_manager** - Docker Swarm manager node
- **komodo_core** - Komodo core node configuration
- **komodo_periphery** - Komodo periphery node configuration

## Module Structure

### Custom Modules

- **orbit-base_server** - Base server configuration including users, SSH, and security
- **orbit-docker** - Docker installation and configuration
- **orbit-swarm** - Docker Swarm cluster management
- **orbit-komodo** - Komodo application deployment and configuration

### External Dependencies

- `puppetlabs/stdlib` (~> 8.0)
- `puppetlabs/apt` (~> 8.0)
- `puppetlabs/nftables` (~> 1.0)
- `puppetlabs/firewall` (~> 3.0)

## Configuration

### Hiera Data Structure

The configuration uses Hiera 5 with the following hierarchy:

1. **Per-node data** (`nodes.yml`) - Node-specific configurations
2. **Global settings** (`global.yml`) - Shared configuration across all nodes

### Key Configuration Files

- `Puppetfile` - Module dependencies and sources
- `hiera.yml` - Hiera configuration
- `manifests/site.pp` - Main site manifest
- `data/` - Hiera data files

## Getting Started

### Prerequisites

- Puppet 7+ installed on target nodes
- Access to Puppet Forge for external modules
- SSH access to managed nodes

### Installation

TODO: Add repo installation instructions

### Node Classification

Nodes are classified based on their hostname in `data/nodes.yml`. Each node can have multiple roles assigned, which determine which Puppet classes are applied.

Example node configuration:
```yaml
luna.orbit:
  roles:
    - swarm
    - swarm_manager
```

## Security

The base server configuration includes:

- SSH key-based authentication
- Firewall configuration with nftables
- User management with restricted access
- Security hardening measures

## Network Configuration

### Required Ports

- **SSH**: 22/tcp
- **Docker Swarm**: 7946/tcp+udp, 4789/udp
- **Swarm Manager**: 2377/tcp
- **Komodo**: 8120/tcp

## Development

### Adding New Nodes

1. Add the node to `data/nodes.yml`
2. Assign appropriate roles
3. Configure node-specific settings if needed

### Creating New Roles

1. Define the role in `data/roles.yml`
2. Specify required classes and ports
3. Update node configurations to use the new role
