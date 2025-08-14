class swarm::swarm {
  # Ensure Docker is installed and running
  require docker

  # Get manager info from Hiera
  $core_node = lookup('core_node', String, 'first', 'luna.orbit')

  # For now, we'll use a simple approach - workers will need the manager IP
  # In a more sophisticated setup, you'd use service discovery
  $manager_ip = case $core_node {
    'luna.orbit': { '10.0.0.10' }  # Replace with actual IP
    default: { '10.0.0.10' }
  }

  # This is a placeholder - workers need manual join for now
  # In production, you'd use a service discovery mechanism
  # or shared storage for token distribution

  notify { 'swarm_worker_setup':
    message => "Swarm worker setup - manual join required to ${core_node}",
  }

  # Create a script for manual swarm join
  file { '/usr/local/bin/join-swarm.sh':
    ensure  => file,
    mode    => '0755',
    content => "#!/bin/bash\n# Run this script on the manager to get the join command:\n# docker swarm join-token worker\n# Then run the resulting command on this worker node\necho 'Get join token from manager: docker swarm join-token worker'\n",
  }
}
