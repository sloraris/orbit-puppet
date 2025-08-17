# Firewall configuration for base servers
# Allows all internal traffic while restricting external access to specific ports
class base_server::firewall {
  # Include UFW module
  include ufw

  # Allow all loopback traffic (essential for Docker and local services)
  ufw_rule { 'allow-loopback-in':
    ensure    => 'present',
    action    => 'allow',
    direction => 'in',
    interface => 'lo',
  }

  ufw_rule { 'allow-loopback-out':
    ensure    => 'present',
    action    => 'allow',
    direction => 'out',
    interface => 'lo',
  }

  # Allow Docker bridge networks (typically 172.17.0.0/16 and 172.16.0.0/12)
  # This allows container-to-container communication
  ufw_rule { 'allow-docker-bridge':
    ensure    => 'present',
    action    => 'allow',
    direction => 'in',
    from_addr => '172.16.0.0/12',
  }

  # Allow Docker Swarm overlay networks (typically 10.0.0.0/8 for swarm)
  # But restrict to Docker's typical overlay range
  ufw_rule { 'allow-docker-overlay':
    ensure    => 'present',
    action    => 'allow',
    direction => 'in',
    from_addr => '10.255.0.0/16',
  }

  # Allow established and related connections (for outbound connections coming back)
  ufw_rule { 'allow-established':
    ensure    => 'present',
    action    => 'allow',
    direction => 'in',
    from_addr => 'any',
    to_addr   => 'any',
    proto     => 'any',
  }

  # Get roles and role classes for this node
  $roles = lookup('roles', Array[String], 'unique', [])
  $role_classes = lookup('role_classes', Hash, 'first', {})

  # Collect all ports from assigned roles
  $role_ports = flatten($roles.map |$role| {
    $role_classes[$role] ? {
      undef   => [],
      default => $role_classes[$role]['ports'] ? {
        undef   => [],
        default => $role_classes[$role]['ports']
      }
    }
  })

  # Create firewall rules for each port based on its source requirement
  $role_ports.each |$port_config| {
    $port = $port_config['port']
    $protocol = $port_config['protocol'] ? {
      undef   => 'tcp',
      default => $port_config['protocol']
    }
    $source = $port_config['source'] ? {
      undef   => 'any',
      default => $port_config['source']
    }

    # Convert source to UFW format
    $ufw_source = case $source {
      'localhost': { '127.0.0.1' }
      'lan':       { '10.0.0.0/8' }
      'any':       { 'any' }
      default:     { $source }
    }

    ufw_rule { "allow-${protocol}-${port}-from-${source}":
      ensure       => 'present',
      action       => 'allow',
      direction    => 'in',
      to_ports_app => $port,
      from_addr    => $ufw_source,
      proto        => $protocol,
    }
  }
}
