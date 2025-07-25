# modules/base_server/manifests/firewall.pp
class base_server::firewall {

  # Include UFW module
  include ufw

  # Enable UFW
  ufw::rule { 'allow-ssh':
    ensure => 'present',
    port   => '22',
    ip     => 'any',
  }

  $roles         = lookup('roles', Array[String], 'unique', [])
  $role_classes  = lookup('role_classes', Hash, 'first', {})

  # Get base ports (applied to all servers)
  $base_ports    = $role_classes['base'] ? {
    undef => [],
    default => $role_classes['base']['ports'] ? {
      undef => [],
      default => $role_classes['base']['ports']
    }
  }

  # Get role-specific ports
  $role_ports    = flatten($roles.map |$role| {
    $role_classes[$role] ? {
      undef => [],
      default => $role_classes[$role]['ports'] ? {
        undef => [],
        default => $role_classes[$role]['ports']
      }
    }
  })

  $all_ports     = unique($base_ports + $role_ports)

  # Allow each port with protocol and source restrictions
  $all_ports.each |$port_config| {
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
      'localhost': {
        '127.0.0.1'
      }
      'lan': {
        '10.0.0.0/8'
      }
      'any': {
        'any'
      }
      default: {
        # If source is a specific IP or CIDR, use it directly
        $source
      }
    }

    ufw::rule { "allow-${protocol}-${port}-from-${source}":
      ensure => 'present',
      port   => $port,
      ip     => $ufw_source,
      proto  => $protocol,
    }
  }

  # Enable UFW with default deny policy
  ufw::rule { 'limit-ssh':
    ensure => 'present',
    port   => '22',
    limit  => true,
  }

  # Set default policies
  ufw::default { 'default-incoming':
    ensure    => 'present',
    direction => 'incoming',
    policy    => 'deny',
  }

  ufw::default { 'default-outgoing':
    ensure    => 'present',
    direction => 'outgoing',
    policy    => 'allow',
  }

  # Enable UFW
  ufw::enable { 'enable-ufw':
    ensure => 'enabled',
  }
}
