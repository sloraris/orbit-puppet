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
}
