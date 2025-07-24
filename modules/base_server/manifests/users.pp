# modules/base_server/manifests/users.pp
class base_server::users {
  $base_users = lookup('base_users', Array[String], 'unique')

  # Ensure default users exist
  $base_users.each |String $user| {
    user { $user:
      ensure => present,
      system => true,
      home   => "/home/${user}",
      shell  => '/bin/bash',
    }

    # Ensure default group exists
    group { $user:
      ensure => present,
      system => true,
    }
  }
}
