class swarm::swarm_manager {
  # Ensure Docker is installed and running
  require docker

  # Get the primary network interface IP
  $manager_ip = $facts['networking']['ip']

  # Initialize swarm if not already active
  exec { 'init_swarm':
    command => "docker swarm init --advertise-addr ${manager_ip}",
    unless  => 'docker info --format "{{.Swarm.LocalNodeState}}" | grep -q active',
    path    => ['/usr/bin', '/bin'],
    require => Service['docker'],
  }

  # Create directory for swarm tokens
  file { '/etc/puppet':
    ensure => directory,
    mode   => '0755',
  }

  # Store manager IP for workers to use
  file { '/etc/puppet/swarm_manager':
    ensure  => file,
    content => "${manager_ip}:2377",
    require => [File['/etc/puppet'], Exec['init_swarm']],
  }

  # Get and store worker join token
  exec { 'get_worker_token':
    command => 'docker swarm join-token -q worker > /etc/puppet/worker_token',
    creates => '/etc/puppet/worker_token',
    path    => ['/usr/bin', '/bin'],
    require => [File['/etc/puppet'], Exec['init_swarm']],
  }

  # Set proper permissions on token file
  file { '/etc/puppet/worker_token':
    ensure  => file,
    mode    => '0644',
    require => Exec['get_worker_token'],
  }
}
