# Automatically include classes based on roles, include base classes for all servers
class base_server::role_manager {
  $roles = lookup('roles', Array[String], 'unique', [])
  $role_classes = lookup('role_classes', Hash, 'first', {})

  # Include base role classes for all servers
  if $role_classes['base'] and $role_classes['base']['classes'] {
    $role_classes['base']['classes'].each |$class| {
      include $class
    }
  }

  # Include classes for each assigned role
  $roles.each |$role| {
    if $role_classes[$role] and $role_classes[$role]['classes'] {
      $role_classes[$role]['classes'].each |$class| {
        include $class
      }
    }
  }
}
