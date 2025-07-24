# modules/base_server/manifests/apt.pp
class base_server::apt {
  # Ensure apt module is properly configured
  class { 'apt':
    update => {
      frequency => 'daily',
      loglevel  => 'notice',
    },
    purge => {
      'sources.list'   => true,
      'sources.list.d' => true,
      'preferences.d'  => true,
    },
  }
}
