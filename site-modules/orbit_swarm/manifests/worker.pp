class orbit_swarm::worker {
  # Ensure Docker is installed first
  require docker

  # Get configuration from Hiera
  $manager_ip = lookup('docker_swarm_manager_ip', String, 'first', '10.0.3.11')
  $advertise_addr = lookup('docker_swarm_advertise_addr', String, 'first', $facts['networking']['ip'])

  # Join Docker Swarm as worker
  # Note: This requires the swarm to already be initialized and tokens to be available
  # In practice, you might need to run this manually or use exported resources
  docker::swarm { 'swarm_worker':
    join           => true,
    advertise_addr => $advertise_addr,
    listen_addr    => $advertise_addr,
    manager_ip     => "${manager_ip}:2377",
    # Token will be retrieved automatically by the module if available
  }
}
