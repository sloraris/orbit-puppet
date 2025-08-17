class base_server {
  # Initialize base system
  contain base_server::apt
  contain base_server::users
  contain base_server::ssh
  contain base_server::firewall
  contain komodo::periphery

  # Ensure proper ordering
  Class['base_server::apt']
  -> Class['base_server::users']
  -> Class['base_server::ssh']
  -> Class['base_server::firewall']
}
