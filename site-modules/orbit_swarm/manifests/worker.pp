class orbit_swarm::worker {
  # Ensure Docker is installed first
  require docker

  # Get configuration from Hiera
  $manager_ip = lookup('docker_swarm_manager_ip', String, 'first', '10.0.3.11')
  $advertise_addr = lookup('docker_swarm_advertise_addr', String, 'first', $facts['networking']['ip'])

  # Get worker token from external variables using simple script
  $worker_token = generate('/etc/puppet/code/environments/production/scripts/get-external-var.sh', 'docker_swarm.worker_token', '')

  if $worker_token != '' {
    # Join Docker Swarm as worker with token from NAS
    docker::swarm { 'swarm_worker':
      join           => true,
      advertise_addr => $advertise_addr,
      listen_addr    => $advertise_addr,
      manager_ip     => "${manager_ip}:2377",
      token          => $worker_token,
    }
  } else {
    warning('Docker Swarm worker token not available from external variables')

    # Fallback: try to join without explicit token (requires manual setup)
    docker::swarm { 'swarm_worker':
      join           => true,
      advertise_addr => $advertise_addr,
      listen_addr    => $advertise_addr,
      manager_ip     => "${manager_ip}:2377",
      require        => File['/usr/local/bin/get-external-var.sh'],
    }
  }
}
