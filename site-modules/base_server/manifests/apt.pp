class base_server::apt {
  # Use the apt module with conservative settings for Ubuntu 24.10
  class { 'apt':
    update => {
      frequency => 'daily',
      loglevel  => 'notice',
    },
    purge  => {
      'sources.list'   => false,  # Don't purge sources.list on newer Ubuntu
      'sources.list.d' => false,  # Don't purge sources.list.d on newer Ubuntu
      'preferences.d'  => false,  # Don't purge preferences.d on newer Ubuntu
    },
  }

  # Install essential packages
  package { ['curl', 'wget', 'ca-certificates', 'software-properties-common']:
    ensure  => present,
    require => Class['apt'],
  }
}
