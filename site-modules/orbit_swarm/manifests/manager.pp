class orbit_swarm::manager {
  # Ensure Docker is installed first
  require docker

  # Get the advertise address from Hiera or use the primary IP
  $advertise_addr = lookup('docker_swarm_advertise_addr', String, 'first', $facts['networking']['ip'])

  # Initialize Docker Swarm
  docker::swarm { 'swarm_manager':
    init           => true,
    advertise_addr => $advertise_addr,
    listen_addr    => $advertise_addr,
  }

  # Simple script to update tokens on NAS after swarm init
  file { '/usr/local/bin/update-swarm-tokens':
    ensure  => file,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('orbit_swarm/update-swarm-tokens.sh.erb'),
    require => Docker::Swarm['swarm_manager'],
  }

  # Run the token update script once after swarm initialization
  exec { 'update-swarm-tokens':
    command     => '/usr/local/bin/update-swarm-tokens',
    refreshonly => true,
    subscribe   => Docker::Swarm['swarm_manager'],
    require     => File['/usr/local/bin/update-swarm-tokens'],
  }
}
