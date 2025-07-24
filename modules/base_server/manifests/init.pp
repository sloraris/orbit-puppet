class base_server {
  # Initialize
  contain base_server::apt
  contain base_server::users
  contain base_server::ssh

  # Harden
  contain base_server::firewall

  # Setup
  #### TODO: automatic wazuh server discovery
  # include base_server::wazuh
  #### TODO: setup metrics and logs export (agent?)

  # Apply role-based manifests
  include base_server::role_manager
}
