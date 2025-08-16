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

  # Enable universe repo
  apt::source { 'ubuntu-universe':
    location => 'http://archive.ubuntu.com/ubuntu',
    release  => $facts['os']['distro']['codename'],
    repos    => 'universe',
    include  => {
      'src' => false,
    },
    require  => Class['apt'],
  }

  # Install essential packages
  package { ['curl', 'wget', 'ca-certificates', 'software-properties-common']:
    ensure  => present,
    require => [Class['apt'], Apt::Source['ubuntu-universe']],
  }
}
