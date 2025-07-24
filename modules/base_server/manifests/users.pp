# modules/base_server/manifests/users.pp
class base_server::users (
  Array[String] $base_users = lookup('base_server::users::base_users'),
) {

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
