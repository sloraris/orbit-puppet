node default {
  contain base_server

  include lookup('classes', Array[String], 'unique', [])
}
