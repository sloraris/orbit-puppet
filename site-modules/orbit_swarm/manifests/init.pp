# Class: orbit_swarm
#
# Simple Docker Swarm management
#
class orbit_swarm (
  String $role = 'worker', # 'manager' or 'worker'
) {
  include 'docker'

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
