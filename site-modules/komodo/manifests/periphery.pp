class komodo::periphery {
  # Ensure Docker is installed first
  # require docker

  # Generate periphery config
  # TODO: lookup periphery port in roles.yml and add to config

  # Install Komodo Periphery
  exec { 'install_komodo_periphery':
    command     => 'curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3',
    path        => ['/usr/bin', '/bin', '/usr/sbin'],
    environment => [
        'HOME=/root'
    ],
    unless      => 'systemctl status periphery.service',
    timeout     => 0,
    notify      => Service['periphery'],
  }

  # Ensure periphery service is running and enabled
  service { 'periphery':
    ensure  => running,
    enable  => true,
    require => Exec['install_komodo_periphery'],
  }

}
