node default {
  # Always include base server configuration
  include base_server

  # Get roles for this node
  $node_roles = lookup('roles', Array[String], 'unique', [])

  # Apply role-based classes
  $node_roles.each |String $role| {
    $role_classes = lookup("role_classes.${role}.classes", Array[String], 'unique', [])
    $role_classes.each |String $class_name| {
      include $class_name
    }
  }
}
