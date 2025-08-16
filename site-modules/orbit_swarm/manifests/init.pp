# Class: orbit_swarm
#
# Simple Docker Swarm management
#
class orbit_swarm (
  String $role = 'worker', # 'manager' or 'worker'
) {

  class { 'docker':
  use_upstream_package_source => false,
  service_overrides_template  => false,
  docker_ce_package_name      => 'docker',
  }

  case $role {
    'manager': {
      include orbit_swarm::manager
    }
    'worker': {
      include orbit_swarm::worker
    }
    default: {
      fail("Invalid role: ${role}. Must be 'manager' or 'worker'")
    }
  }
}
