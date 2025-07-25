# modules/base_server/manifests/firewall.pp
class base_server::firewall {

  # Include UFW module
  include ufw

  # Enable UFW with default allow SSH and deny all other traffic policy
  ufw_rule { 'limit-ssh':
    ensure        => 'present',
    to_ports_app  => '22',
    action        => 'allow',
    direction     => 'in',
    from_addr     => '10.0.0.0/8',
  }

  # Lookup ports from roles.yaml
  $roles         = lookup('roles', Array[String], 'unique', [])
  $role_classes  = lookup('role_classes', Hash, 'first', {})

  # Debug output
  notify { "Debug - Roles lookup result: ${roles}": }
  notify { "Debug - Role classes lookup result: ${role_classes}": }
  notify { "Debug - Role classes keys: ${role_classes.keys}": }

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

  # Debug output
  notify { "Debug - Base ports: ${base_ports}": }
  notify { "Debug - Role ports: ${role_ports}": }
  notify { "Debug - All ports: ${all_ports}": }

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
        $source
      }
    }

    notify { "Debug - Creating rule for port ${port} ${protocol} from ${source} (${ufw_source})": }

    ufw_rule { "allow-${protocol}-${port}-from-${source}":
      ensure          => 'present',
      action          => 'allow',
      direction       => 'in',
      to_ports_app    => $port,
      from_addr       => $ufw_source,
      proto           => $protocol,
    }
  }
}
