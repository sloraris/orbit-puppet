class docker {
  # Add Docker's official GPG key and repository
  exec { 'add_docker_gpg_key':
    command => 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg',
    path    => ['/usr/bin', '/bin'],
    unless  => 'test -f /usr/share/keyrings/docker-archive-keyring.gpg',
    require => Package['curl', 'gnupg'],
  }

  # Add Docker repository
  file { '/etc/apt/sources.list.d/docker.list':
    ensure  => file,
    content => "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu ${facts['os']['distro']['codename']} stable\n",
    require => Exec['add_docker_gpg_key'],
    notify  => Exec['apt_update_docker'],
  }

  # Update apt cache for Docker repo
  exec { 'apt_update_docker':
    command     => 'apt-get update',
    path        => ['/usr/bin', '/bin'],
    refreshonly => true,
  }

  # Install required packages
  package { ['curl', 'gnupg', 'ca-certificates']:
    ensure => present,
  }

  # Install Docker packages
  package { [
    'docker-ce',
    'docker-ce-cli',
    'containerd.io',
    'docker-buildx-plugin',
    'docker-compose-plugin',
  ]:
    ensure  => present,
    require => [File['/etc/apt/sources.list.d/docker.list'], Exec['apt_update_docker']],
  }

  # Ensure Docker service is running
  service { 'docker':
    ensure  => running,
    enable  => true,
    require => Package['docker-ce'],
  }

  # Add orbit user to docker group
  $orbit_user = lookup('base_users', Array[String], 'unique', ['orbit'])[0]

  exec { 'add_user_to_docker_group':
    command => "usermod -aG docker ${orbit_user}",
    path    => ['/usr/sbin', '/usr/bin', '/bin'],
    unless  => "groups ${orbit_user} | grep docker",
    require => [Package['docker-ce'], User[$orbit_user]],
  }
}
