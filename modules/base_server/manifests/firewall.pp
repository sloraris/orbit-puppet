# modules/base_server/manifests/firewall.pp
class base_server::firewall {

  include nftables

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

  # Flush existing rules only once during initial Puppet runs (optional but recommended)
  nftables::rule { 'flush-rules':
    content => 'flush ruleset',
    order   => '000',
  }

  # Accept established connections
  nftables::rule { 'accept-established':
    content => 'ct state established,related accept',
    table   => 'inet',
    chain   => 'input',
    order   => '100',
  }

  # Accept loopback
  nftables::rule { 'allow-loopback':
    content => 'iifname lo accept',
    table   => 'inet',
    chain   => 'input',
    order   => '110',
  }

  # Allow each port with protocol and source restrictions
  $all_ports.each |$port_config, $i| {
    $port = $port_config['port']
    $protocol = $port_config['protocol'] ? {
      undef => 'tcp',
      default => $port_config['protocol']
    }
    $source = $port_config['source'] ? {
      undef => 'any',
      default => $port_config['source']
    }

    # Build the rule content based on source restriction
    $rule_content = case $source {
      'localhost': {
        "${protocol} dport ${port} iifname lo accept"
      }
      'lan': {
        "${protocol} dport ${port} ip saddr 10.0.0.0/8 accept"
      }
      'any': {
        "${protocol} dport ${port} accept"
      }
      default: {
        # If source is a specific IP or CIDR, use it directly
        "${protocol} dport ${port} ip saddr ${source} accept"
      }
    }

    nftables::rule { "allow-${protocol}-port-${port}-from-${source}":
      content => $rule_content,
      table   => 'inet',
      chain   => 'input',
      order   => "2${i}",
    }
  }

  # Drop everything else
  nftables::rule { 'drop-all':
    content => 'drop',
    table   => 'inet',
    chain   => 'input',
    order   => '999',
  }
}
