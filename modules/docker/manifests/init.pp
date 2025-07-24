class docker {

  # Install Docker
  exec { 'install_docker':
    command => 'curl -fsSL https://get.docker.com | sh',
    path    => ['/usr/bin', '/bin'],
    unless  => 'which docker',
  }

  # Docker version control
  package { [
    'docker-ce',
    'docker-ce-cli',
    'containerd.io',
    'docker-buildx-plugin',
    'docker-compose-plugin',
  ]:
    ensure => latest,
  }
}
