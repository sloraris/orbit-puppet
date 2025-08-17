class base_server::firewall {
  # Include UFW module
  include ufw

  # Always allow SSH from LAN
  ufw_rule { 'allow-ssh-lan':
    ensure     => 'present',
    to_ports_app => '22',
    action     => 'allow',
    direction  => 'in',
    from_addr  => '10.0.0.0/8',
  }

  # Always allow internal docker traffic
  ufw_rule {'allow-docker-internal':
    ensure     => 'present',
    to_ports_app => 'lo',
    action     => 'allow',
    direction  => 'both',
    from_addr  => 'lo',
  }

  # Get roles and role classes for this node
  $roles = lookup('roles', Array[String], 'unique', [])
  $role_classes = lookup('role_classes', Hash, 'first', {})

  # Collect all ports from assigned roles
  $role_ports = flatten($roles.map |$role| {
    $role_classes[$role] ? {
      undef => [],
      default => $role_classes[$role]['ports'] ? {
        undef => [],
        default => $role_classes[$role]['ports']
      }
    }
  })

  # Create firewall rules for each port
  $role_ports.each |$port_config| {
    $port = $port_config['port']
    $protocol = $port_config['protocol'] ? {
      undef => 'tcp',
      default => $port_config['protocol']
    }
    $source = $port_config['source'] ? {
      undef => 'any',
      default => $port_config['source']
    }

    # Convert source to UFW format
    $ufw_source = case $source {
      'localhost': { '127.0.0.1' }
      'lan': { '10.0.0.0/8' }
      'any': { 'any' }
      default: { $source }
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
