node default {
  contain base_server

  include lookup('roles', Array[String], 'unique', [])
}
