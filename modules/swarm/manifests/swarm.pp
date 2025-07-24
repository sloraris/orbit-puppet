# modules/swarm/manifests/swarm.pp
class swarm::swarm {
  $manager_ip = file('/etc/puppet/swarm_manager')
  $file_token = file('/etc/puppet/worker_token')

  # Ensure Docker is installed first
  require docker

  # Join swarm
  exec { 'join_swarm':
    command => "docker swarm join --token ${file_token} manager_ip:2377",
    unless  => 'docker info | grep "Swarm: active"',
    path    => ['/usr/bin', '/bin'],
  }
}
