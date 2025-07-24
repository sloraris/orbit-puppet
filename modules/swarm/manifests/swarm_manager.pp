# modules/swarm/manifests/swarm_manager.pp
class swarm::swarm_manager {
  # Ensure Docker is installed first
  require docker

  # Initialize swarm
  exec { 'init_swarm':
    command => 'docker swarm init',
    unless  => 'docker info | grep "Swarm: active"',
    path    => ['/usr/bin', '/bin'],
  }

  # Set manager info
  file { '/etc/puppet/swarm_manager':
    ensure  => file,
    content => "${::ipaddress_eth0}:2377",
  }

  # Issue join token
  exec { 'get_worker_token':
    command => 'docker swarm join-token -q worker > /etc/puppet/worker_token',
    unless  => 'test -f /etc/puppet/worker_token',
    path    => ['/usr/bin', '/bin'],
  }
}
