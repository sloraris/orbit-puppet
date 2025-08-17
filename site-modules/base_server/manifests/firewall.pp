# Firewall configuration for base servers using iptables
# Docker-friendly approach that doesn't interfere with container networking
class base_server::firewall {
  # Ensure iptables is installed and UFW is disabled
  package { 'iptables-persistent':
    ensure => present,
  }

  service { 'ufw':
    ensure => stopped,
    enable => false,
  }

  # Create custom iptables chain for our rules
  exec { 'create-custom-chain':
    command => '/sbin/iptables -t filter -N PUPPET_INPUT 2>/dev/null || true',
    unless  => '/sbin/iptables -t filter -L PUPPET_INPUT 2>/dev/null',
    require => Package['iptables-persistent'],
  }

  # Basic iptables rules that work with Docker
  # Allow loopback traffic
  firewall { '001 allow loopback':
    proto  => 'all',
    iniface => 'lo',
    action => 'accept',
  }

  # Allow established and related connections
  firewall { '002 allow established':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  # Allow all traffic on Docker interfaces (let Docker manage its own rules)
  firewall { '003 allow docker0':
    proto   => 'all',
    iniface => 'docker0',
    action  => 'accept',
  }

  # Allow traffic between Docker containers on bridge networks
  firewall { '004 allow docker bridge':
    proto  => 'all',
    source => '172.16.0.0/12',
    action => 'accept',
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

  # Create iptables rules for each port based on its source requirement
  $role_ports.each |$index, $port_config| {
    $port = $port_config['port']
    $protocol = $port_config['protocol'] ? {
      undef   => 'tcp',
      default => $port_config['protocol']
    }
    $source = $port_config['source'] ? {
      undef   => 'any',
      default => $port_config['source']
    }

    # Convert source to iptables format
    $rule_number = sprintf('%03d', 100 + $index)

    case $source {
      'localhost': {
        firewall { "${rule_number} allow ${protocol}/${port} from localhost":
          proto  => $protocol,
          dport  => $port,
          source => '127.0.0.1/32',
          action => 'accept',
        }
      }
      'lan': {
        firewall { "${rule_number} allow ${protocol}/${port} from lan":
          proto  => $protocol,
          dport  => $port,
          source => '10.0.0.0/8',
          action => 'accept',
        }
      }
      'any': {
        firewall { "${rule_number} allow ${protocol}/${port} from any":
          proto  => $protocol,
          dport  => $port,
          action => 'accept',
        }
      }
      default: {
        firewall { "${rule_number} allow ${protocol}/${port} from ${source}":
          proto  => $protocol,
          dport  => $port,
          source => $source,
          action => 'accept',
        }
      }
    }
  }

  # Drop all other incoming traffic (but allow outgoing)
  firewall { '999 drop all other input':
    proto  => 'all',
    action => 'drop',
    before => undef,
  }
}
