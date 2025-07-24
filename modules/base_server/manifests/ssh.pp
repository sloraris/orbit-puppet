# modules/base_server/manifests/ssh.pp
class base_server::ssh {
  $github_user = lookup('github_user', String)
  $ssh_user    = lookup('ssh_user', String)

  # Ensure user's .ssh directory exists
  file { "/home/${ssh_user}/.ssh":
    ensure  => directory,
    owner   => $ssh_user,
    group   => $ssh_user,
    mode    => '0700',
  }

  # Fetch GitHub keys if:
  # 1. They don't exist
  # 2. They are different than the existing ones on the server
  exec { "fetch_github_keys_${ssh_user}":
    command => "/usr/bin/curl -s https://github.com/${github_user}.keys -o /home/${ssh_user}/.ssh/authorized_keys",
    user    => $ssh_user,
    require => File["/home/${ssh_user}/.ssh"],
    unless  => "/usr/bin/curl -s https://github.com/${github_user}.keys | /usr/bin/diff -q - /home/${ssh_user}/.ssh/authorized_keys",
  }

  # Ensure authorized_keys file exists
  file { "/home/${ssh_user}/.ssh/authorized_keys":
    ensure  => file,
    owner   => $ssh_user,
    group   => $ssh_user,
    mode    => '0600',
    require => Exec["fetch_github_keys_${ssh_user}"],
  }

  # Disable password login over ssh
  file_line { 'disable_password_authentication':
    ensure => present,
    path   => '/etc/ssh/sshd_config',
    line   => 'PasswordAuthentication no',
    match  => '^#?PasswordAuthentication',
    notify => Service['ssh'],
  }

  # Disable root login over ssh
  file_line { 'disable_root_login':
    ensure => present,
    path   => '/etc/ssh/sshd_config',
    line   => 'PermitRootLogin no',
    match  => '^#?PermitRootLogin',
    notify => Service['ssh'],
  }

  # Ensure ssh service is running
  service { 'ssh':
    ensure => running,
    enable => true,
  }
}
