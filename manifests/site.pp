node default {
  # Always include base server configuration
  include base_server

  # Get roles for this node
  $node_roles = lookup('roles', Array[String], 'unique', [])

  # Get all role class definitions
  $all_role_classes = lookup('role_classes', Hash, 'first', {})

  # Apply role-based classes
  $node_roles.each |String $role| {
    if $all_role_classes[$role] and $all_role_classes[$role]['classes'] {
      $role_classes = $all_role_classes[$role]['classes']
      $role_classes.each |String $class_name| {
        include $class_name
      }
    }
  }
}
